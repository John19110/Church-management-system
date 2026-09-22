using AutoMapper;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Church.BLL.Abstractions;
using Church.BLL.Abstractions.Caching;
using Church.BLL.DTOS;
using Church.BLL.DTOS.AccountDtos;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;
using Church.DAL.Abstractions;
using Church.DAL.Repository.Interfaces;
using Church.DAL.Models;
using Church.Domain;

namespace Church.BLL.Manager.Implementations
{
    public class ServantManager : IServantManager
    {
        private readonly IServantRepository _servantRepository;
        private readonly ITenantContext _tenantContext;
        private readonly ICurrentUserContext _currentUser;
        private readonly IAccountManager _accountManager;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IMapper _mapper;
        private readonly ICacheService _cache;
        private readonly ICacheKeyBuilder _cacheKeys;
        private readonly ICacheContextAccessor _cacheContext;

        public ServantManager(
            IServantRepository servantRepository,
            ITenantContext tenantContext,
            ICurrentUserContext currentUser,
            IMapper mapper,
            IAccountManager accountManager,
            UserManager<ApplicationUser> usermanager,
            ICacheService cache,
            ICacheKeyBuilder cacheKeys,
            ICacheContextAccessor cacheContext)
        {
            _servantRepository = servantRepository;
            _tenantContext = tenantContext;
            _currentUser = currentUser;
            _mapper = mapper;
            _accountManager = accountManager;
            _userManager = usermanager;
            _cache = cache;
            _cacheKeys = cacheKeys;
            _cacheContext = cacheContext;
        }

        public async Task AddAsync(AdminAddServantDTO servantDto, string webRootPath)
        {
            var registerDTO = _mapper.Map<RegisterServantDTO>(servantDto.Account);
            registerDTO.Image = servantDto.Servant.Image;

            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing");

            var meetingId = _tenantContext.MeetingId
                ?? throw new UnauthorizedAccessException("MeetingId claim is missing");

            await _accountManager.RegisterServantForTenant(
                registerDTO,
                churchId,
                meetingId,
                webRootPath);

            var phone = registerDTO.PhoneNumber.Trim().Replace(" ", "");
            var user = await _userManager.Users.FirstOrDefaultAsync(u => u.PhoneNumber == phone);
            if (user == null)
                throw new InvalidOperationException("Servant user was not created.");

            user.IsApproved = true;
            user.PhoneNumberConfirmed = true;
            await _userManager.UpdateAsync(user);

            await InvalidateMinistriesCachesAsync();
        }

        public async Task<IEnumerable<ServantReadDTO>> GetAllAsync()
        {
            // Servants may only list peers in their own meeting; enforce explicitly (not only via EF filters).
            if (_currentUser.IsInRole("Servant"))
            {
                var meetingId = await GetCallerMeetingIdOrThrowAsync();
                return await LoadByMeetingIdCachedAsync(meetingId);
            }

            IEnumerable<ServantReadDTO> servants;
            var ctx = _cacheContext.TryGet();
            if (ctx is null || string.IsNullOrWhiteSpace(ctx.Role))
            {
                var raw = await _servantRepository.GetAllAsync();
                servants = _mapper.Map<IEnumerable<ServantReadDTO>>(raw);
            }
            else
            {
                // Meeting-scoped tenants share a church+role cache segment; key MUST include MeetingId
                // or Admin A and Admin B in different meetings bleed lists across each other.
                var meetingKey = _tenantContext.MeetingId is int mid && mid > 0
                    ? (object)mid
                    : "all";
                var key = _cacheKeys.TenantRole(
                    ctx.Role!,
                    "ministries",
                    ("resource", "servants"),
                    ("meetingId", meetingKey));
                servants = await _cache.GetOrCreateAsync(
                    key,
                    new CacheEntryOptions(CacheTtls.Ministries),
                    ctx,
                    async _ =>
                    {
                        var raw = await _servantRepository.GetAllAsync();
                        return _mapper.Map<List<ServantReadDTO>>(raw);
                    });
            }

            // Return every approved servant in the caller's tenant/meeting scope (including self).
            // Hiding the caller previously made sole-admin/superadmin churches show an empty list.
            return servants;
        }

        public async Task<IEnumerable<ServantReadDTO>> GetByMeetingIdAsync(int meetingId)
        {
            await EnsureServantCanAccessMeetingAsync(meetingId);

            return await LoadByMeetingIdCachedAsync(meetingId);
        }

        private async Task<IEnumerable<ServantReadDTO>> LoadByMeetingIdCachedAsync(int meetingId)
        {
            IEnumerable<ServantReadDTO> servants;
            var ctx = _cacheContext.TryGet();
            if (ctx is null || string.IsNullOrWhiteSpace(ctx.Role))
            {
                var raw = await _servantRepository.GetByMeetingIdAsync(meetingId);
                servants = _mapper.Map<IEnumerable<ServantReadDTO>>(raw);
            }
            else
            {
                var key = _cacheKeys.TenantRole(ctx.Role!, "ministries", ("meetingId", meetingId));
                servants = await _cache.GetOrCreateAsync(
                    key,
                    new CacheEntryOptions(CacheTtls.Ministries),
                    ctx,
                    async _ =>
                    {
                        var raw = await _servantRepository.GetByMeetingIdAsync(meetingId);
                        return _mapper.Map<List<ServantReadDTO>>(raw);
                    });
            }

            return servants;
        }

        private async Task<int> GetCallerMeetingIdOrThrowAsync()
        {
            if (_tenantContext.MeetingId is int meetingId && meetingId > 0)
                return meetingId;

            if (string.IsNullOrWhiteSpace(_currentUser.UserId))
                throw new UnauthorizedAccessException("Meeting context is missing.");

            var me = await _servantRepository.GetByApplicationUserIdAsync(_currentUser.UserId);
            if (me?.MeetingId is int servantMeetingId && servantMeetingId > 0)
                return servantMeetingId;

            throw new UnauthorizedAccessException("Meeting context is missing.");
        }

        private async Task EnsureServantCanAccessMeetingAsync(int meetingId)
        {
            if (!_currentUser.IsInRole("Servant"))
                return;

            var callerMeetingId = await GetCallerMeetingIdOrThrowAsync();
            if (callerMeetingId != meetingId)
            {
                throw new UnauthorizedAccessException(
                    "You can only view servants assigned to your meeting.");
            }
        }

        private async Task InvalidateMinistriesCachesAsync()
        {
            var ctx = _cacheContext.TryGet();
            if (ctx is null)
                return;

            await _cache.RemoveTenantSegmentAsync("ministries", ctx);
            await _cache.RemoveTenantSegmentAsync("dashboard", ctx);
        }

        public async Task<List<SelectOptionDTO>> GetServantsForSelection()
        {
            var ctx = _cacheContext.TryGet();
            if (ctx is null || string.IsNullOrWhiteSpace(ctx.Role))
            {
                var raw = await _servantRepository.GetServantsForSelection();
                return raw.Select(s => new SelectOptionDTO { Id = s.Id, Name = s.Item2 }).ToList();
            }

            var meetingKey = _tenantContext.MeetingId is int mid && mid > 0
                ? (object)mid
                : "all";
            var key = _cacheKeys.TenantRole(
                ctx.Role!,
                "ministries",
                ("view", "select"),
                ("meetingId", meetingKey));
            return await _cache.GetOrCreateAsync(
                key,
                new CacheEntryOptions(CacheTtls.Ministries),
                ctx,
                async _ =>
                {
                    var raw = await _servantRepository.GetServantsForSelection();
                    return raw.Select(s => new SelectOptionDTO { Id = s.Id, Name = s.Item2 }).ToList();
                });
        }

        public async Task<ServantReadDTO?> GetByIdAsync(int id)
        {
            if (id <= 0)
                return null;

            var servant = await _servantRepository.GetByIdAsync(id);
            if (servant == null)
                return null;

            if (_currentUser.IsInRole("Servant"))
            {
                if (servant.MeetingId is not int meetingId || meetingId <= 0)
                    return null;

                await EnsureServantCanAccessMeetingAsync(meetingId);
            }

            return await MapToReadDtoAsync(servant);
        }

        public async Task EnsureCanViewServantAsync(int servantId)
        {
            if (servantId <= 0)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["id"] = new[] { "Servant id must be a positive integer." }
                });
            }

            if (!_currentUser.IsInRole("Servant"))
                return;

            var servant = await _servantRepository.GetByIdAsync(servantId);
            if (servant == null)
                throw new NotFoundException($"Servant with id {servantId} not found.");

            if (servant.MeetingId is not int meetingId || meetingId <= 0)
            {
                throw new UnauthorizedAccessException(
                    "You can only view servants assigned to your meeting.");
            }

            await EnsureServantCanAccessMeetingAsync(meetingId);
        }

        public async Task EnsureCanModifyServantAsync(int servantId)
        {
            if (servantId <= 0)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["id"] = new[] { "Servant id must be a positive integer." }
                });
            }

            if (_currentUser.IsInRole("Servant"))
            {
                var callerServantId = await GetCallerServantIdAsync();
                if (!callerServantId.HasValue || callerServantId.Value != servantId)
                {
                    throw new UnauthorizedAccessException(
                        "You can only edit your own servant profile.");
                }

                return;
            }

            if (_currentUser.IsInRole("Admin") && !_currentUser.IsInRole("SuperAdmin"))
            {
                var callerServantId = await GetCallerServantIdAsync();
                if (callerServantId.HasValue && callerServantId.Value == servantId)
                    return;

                await EnsureTargetIsNotAdminOrSuperAdminAsync(servantId);
            }
        }

        private async Task EnsureTargetIsNotAdminOrSuperAdminAsync(int servantId)
        {
            var servant = await _servantRepository.GetByIdAsync(servantId);
            if (servant == null)
                throw new NotFoundException($"Servant with id {servantId} not found.");

            if (string.IsNullOrWhiteSpace(servant.ApplicationUserId))
                return;

            var user = await _userManager.FindByIdAsync(servant.ApplicationUserId);
            if (user == null)
                return;

            var roles = await _userManager.GetRolesAsync(user);
            if (roles.Any(static r =>
                    string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(r, "SuperAdmin", StringComparison.OrdinalIgnoreCase)))
            {
                throw new UnauthorizedAccessException(
                    "Meeting admins cannot edit admin or super admin accounts.");
            }
        }

        private async Task<ServantReadDTO> MapToReadDtoAsync(Servant servant)
        {
            var dto = _mapper.Map<ServantReadDTO>(servant);

            if (!string.IsNullOrWhiteSpace(servant.ApplicationUserId))
            {
                var user = await _userManager.FindByIdAsync(servant.ApplicationUserId);
                if (user != null)
                    dto.Roles = (await _userManager.GetRolesAsync(user)).ToList();
            }

            return dto;
        }

        private async Task<int?> GetCallerServantIdAsync()
        {
            if (string.IsNullOrWhiteSpace(_currentUser.UserId))
                return null;

            var me = await _servantRepository.GetByApplicationUserIdAsync(_currentUser.UserId);
            return me?.Id;
        }

        public async Task UpdateAsync(ServantUpdateDTO servantUpdateDTO)
        {
            await EnsureCanModifyServantAsync(servantUpdateDTO.Id);

            var existing = await _servantRepository.GetByIdAsync(servantUpdateDTO.Id);

            if (existing == null)
                throw new NotFoundException($"Servant with id {servantUpdateDTO.Id} not found.");

            _mapper.Map(servantUpdateDTO, existing);

            if (!string.IsNullOrWhiteSpace(servantUpdateDTO.PhoneNumber) &&
                existing.ApplicationUser != null)
            {
                existing.ApplicationUser.PhoneNumber =
                    servantUpdateDTO.PhoneNumber.Trim().Replace(" ", "");
            }

            await _servantRepository.UpdateAsync(existing);
            await InvalidateMinistriesCachesAsync();
        }

        public async Task<bool> DeleteAsync(int id)
        {
            if (id <= 0)
                return false;

            await EnsureCanModifyServantAsync(id);

            // The cascade delete below runs unscoped, so ownership must be proven here first.
            // This tenant-filtered read returns null for a servant in another church or meeting,
            // which is what stops an admin from deleting across tenants by guessing an id.
            var servant = await _servantRepository.GetByIdAsync(id);
            if (servant == null)
                return false;

            var outcome = await _servantRepository.DeleteAsync(id);
            if (!outcome.Deleted)
                return false;

            if (!string.IsNullOrEmpty(outcome.ApplicationUserId))
            {
                var user = await _userManager.FindByIdAsync(outcome.ApplicationUserId);
                if (user != null)
                    await _userManager.UpdateSecurityStampAsync(user);
            }

            await InvalidateMinistriesCachesAsync();
            return true;
        }
    }
}
