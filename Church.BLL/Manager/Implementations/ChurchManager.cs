using Church.BLL.DTOS.ChurchDtos;
using Church.BLL.Abstractions;
using Church.BLL.Abstractions.Caching;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;
using Church.DAL.Abstractions;
using Church.DAL.Repository.Interfaces;

namespace Church.BLL.Manager.Implementations
{
    public class ChurchManager : IChurchManager
    {
        private readonly IChurchRepository _churchRepository;
        private readonly IServantRepository _servantRepository;
        private readonly ICacheService _cache;
        private readonly ICacheKeyBuilder _cacheKeys;
        private readonly ICacheContextAccessor _cacheContext;
        private readonly ITenantContext _tenantContext;
        private readonly ICurrentUserContext _currentUser;

        public ChurchManager(
            IChurchRepository churchRepository,
            IServantRepository servantRepository,
            ICacheService cache,
            ICacheKeyBuilder cacheKeys,
            ICacheContextAccessor cacheContext,
            ITenantContext tenantContext,
            ICurrentUserContext currentUser)
        {
            _churchRepository = churchRepository;
            _servantRepository = servantRepository;
            _cache = cache;
            _cacheKeys = cacheKeys;
            _cacheContext = cacheContext;
            _tenantContext = tenantContext;
            _currentUser = currentUser;
        }

        /// <summary>
        /// The church repository intentionally bypasses global query filters (join-by-code and
        /// login run without a tenant), so every church read/write reached from an API route must
        /// re-assert the tenant boundary here. Without this a caller from church A can read or
        /// rename church B just by changing the route id.
        /// </summary>
        private void EnsureCallerOwnsChurch(int churchId)
        {
            if (!_currentUser.IsAuthenticated)
                throw new UnauthorizedAccessException("User is not authenticated.");

            var callerChurchId = _tenantContext.ChurchId;
            if (callerChurchId is null or <= 0)
                throw new UnauthorizedAccessException("ChurchId claim is missing.");

            if (callerChurchId.Value != churchId)
                throw new UnauthorizedAccessException("This church does not belong to your tenant.");
        }

        public async Task<ChurchReadDTO> GetByIdAsync(int id)
        {
            if (id <= 0)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["ChurchId"] = new[] { "Church id must be a positive integer." }
                });

            EnsureCallerOwnsChurch(id);

            var ctx = _cacheContext.TryGet();
            if (ctx is null)
            {
                // Safety: never cache when tenant context is missing.
                return await LoadChurchAsync(id);
            }

            var key = _cacheKeys.Tenant("settings", ("churchId", id));
            return await _cache.GetOrCreateAsync(
                key,
                new CacheEntryOptions(CacheTtls.Settings),
                ctx,
                _ => LoadChurchAsync(id));
        }

        private async Task<ChurchReadDTO> LoadChurchAsync(int id)
        {
            var church = await _churchRepository.GetByIdAsync(id);
            if (church == null)
                throw new NotFoundException($"Church with id {id} not found.");

            string? pastorName = null;
            if (church.PastorId.HasValue)
            {
                var pastor = await _servantRepository.GetByIdAsync(church.PastorId.Value);
                pastorName = pastor?.Name;
            }

            return new ChurchReadDTO
            {
                Id = church.Id,
                PublicId = church.PublicId,
                Name = church.Name,
                PastorId = church.PastorId,
                PastorName = pastorName,
            };
        }

        public async Task UpdateAsync(int id, ChurchUpdateDTO dto, bool generateDefaults = false)
        {
            if (id <= 0)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["ChurchId"] = new[] { "Church id must be a positive integer." }
                });

            if (dto == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Church"] = new[] { "Request body cannot be empty." }
                });

            if (dto.Id != 0 && dto.Id != id)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Id"] = new[] { "The ID in the URL does not match the ID in the request body." }
                });

            EnsureCallerOwnsChurch(id);

            var church = await _churchRepository.GetByIdAsync(id);
            if (church == null)
                throw new NotFoundException($"Church with id {id} not found.");

            if (dto.Name != null)
            {
                var trimmed = dto.Name.Trim();
                church.Name = trimmed;
            }
            else if (generateDefaults && string.IsNullOrWhiteSpace(church.Name))
            {
                church.Name = $"Church {church.Id}";
            }

            if (dto.PastorId.HasValue)
            {
                if (dto.PastorId.Value <= 0)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["PastorId"] = new[] { "Pastor id must be a positive integer." }
                    });

                // Ensure servant exists
                var pastor = await _servantRepository.GetByIdAsync(dto.PastorId.Value);
                if (pastor == null)
                    throw new NotFoundException($"Servant with id {dto.PastorId.Value} not found.");

                church.PastorId = dto.PastorId;
            }

            await _churchRepository.UpdateAsync(church);

            var ctx = _cacheContext.TryGet();
            if (ctx is not null)
            {
                // Church settings changed for this tenant.
                await _cache.RemoveTenantSegmentAsync("settings", ctx);
                await _cache.RemoveTenantSegmentAsync("dashboard", ctx);
            }
        }
    }
}

