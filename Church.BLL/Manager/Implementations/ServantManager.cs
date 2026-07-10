using AutoMapper;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Church.BLL.Abstractions.Caching;
using Church.BLL.DTOS;
using Church.BLL.DTOS.AccountDtos;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;
using Church.DAL.Abstractions;
using Church.DAL.Repository.Interfaces;
using Church.DAL.Models;

namespace Church.BLL.Manager.Implementations
{
    public class ServantManager : IServantManager
    {
        private readonly IServantRepository _servantRepository;
        private readonly ITenantContext _tenantContext;
        private readonly IAccountManager _accountManager;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IMapper _mapper;
        private readonly ICacheService _cache;
        private readonly ICacheKeyBuilder _cacheKeys;
        private readonly ICacheContextAccessor _cacheContext;

        public ServantManager(
            IServantRepository servantRepository,
            ITenantContext tenantContext,
            IMapper mapper,
            IAccountManager accountManager,
            UserManager<ApplicationUser> usermanager,
            ICacheService cache,
            ICacheKeyBuilder cacheKeys,
            ICacheContextAccessor cacheContext)
        {
            _servantRepository = servantRepository;
            _tenantContext = tenantContext;
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
            user.IsPhoneVerified = true;
            user.PhoneNumberConfirmed = true;
            await _userManager.UpdateAsync(user);
        }

        public async Task<IEnumerable<ServantReadDTO>> GetAllAsync()
        {
            var ctx = _cacheContext.TryGet();
            if (ctx is null || string.IsNullOrWhiteSpace(ctx.Role))
            {
                var raw = await _servantRepository.GetAllAsync();
                return _mapper.Map<IEnumerable<ServantReadDTO>>(raw);
            }

            var key = _cacheKeys.TenantRole(ctx.Role!, "ministries", ("resource", "servants"));
            return await _cache.GetOrCreateAsync(
                key,
                new CacheEntryOptions(CacheTtls.Ministries),
                ctx,
                async _ =>
                {
                    var raw = await _servantRepository.GetAllAsync();
                    return _mapper.Map<List<ServantReadDTO>>(raw);
                });
        }

        public async Task<IEnumerable<ServantReadDTO>> GetByMeetingIdAsync(int meetingId)
        {
            var ctx = _cacheContext.TryGet();
            if (ctx is null || string.IsNullOrWhiteSpace(ctx.Role))
            {
                var raw = await _servantRepository.GetByMeetingIdAsync(meetingId);
                return _mapper.Map<IEnumerable<ServantReadDTO>>(raw);
            }

            var key = _cacheKeys.TenantRole(ctx.Role!, "ministries", ("meetingId", meetingId));
            return await _cache.GetOrCreateAsync(
                key,
                new CacheEntryOptions(CacheTtls.Ministries),
                ctx,
                async _ =>
                {
                    var raw = await _servantRepository.GetByMeetingIdAsync(meetingId);
                    return _mapper.Map<List<ServantReadDTO>>(raw);
                });
        }

        public async Task<List<SelectOptionDTO>> GetServantsForSelection()
        {
            var ctx = _cacheContext.TryGet();
            if (ctx is null || string.IsNullOrWhiteSpace(ctx.Role))
            {
                var raw = await _servantRepository.GetServantsForSelection();
                return raw.Select(s => new SelectOptionDTO { Id = s.Id, Name = s.Item2 }).ToList();
            }

            var key = _cacheKeys.TenantRole(ctx.Role!, "ministries", ("view", "select"));
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

            return _mapper.Map<ServantReadDTO>(servant);
        }

        public async Task UpdateAsync(ServantUpdateDTO servantUpdateDTO)
        {
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

            var ctx = _cacheContext.TryGet();
            if (ctx is not null)
            {
                await _cache.RemoveTenantSegmentAsync("ministries", ctx);
                await _cache.RemoveTenantSegmentAsync("dashboard", ctx);
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            if (id <= 0)
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

            var ctx = _cacheContext.TryGet();
            if (ctx is not null)
            {
                await _cache.RemoveTenantSegmentAsync("ministries", ctx);
                await _cache.RemoveTenantSegmentAsync("dashboard", ctx);
            }

            return true;
        }
    }
}
