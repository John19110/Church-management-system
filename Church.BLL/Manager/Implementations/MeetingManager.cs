using AutoMapper;
using Microsoft.AspNetCore.Identity;
using Church.BLL.Abstractions;
using Church.BLL.Abstractions.Caching;
using Church.DAL.Abstractions;
using Microsoft.Extensions.Options;
using Church.BLL.Configuration;
using Church.BLL.DTOS;
using Church.BLL.DTOS.Meeting;
using Church.BLL.DTOS.MeetingDtos;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;
using Church.BLL.Services;
using Church.DAL.Models;
using Church.DAL.Repository.Interfaces;
using Church.Domain;
using Church.DAL.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace Church.BLL.Manager.Implementations
{
    public class MeetingManager:IMeetingManager
    {

        private readonly IClassroomRepository _classroomRepository;
        private readonly ICurrentUserContext _currentUser;
        private readonly ITenantContext _tenantContext;
        private readonly IServantRepository _servantRepo;
        private readonly IMemberRepository _memberRepo;
        private readonly IMapper _mapper;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IMeetingRepository _meetingRepository;
        private readonly ServantProfileOptions _servantProfileOptions;
        private readonly IMeetingPublicIdService _meetingPublicIdService;
        private readonly ICacheService _cache;
        private readonly ICacheKeyBuilder _cacheKeys;
        private readonly ICacheContextAccessor _cacheContext;


        public MeetingManager(ICurrentUserContext currentUser,
                ITenantContext tenantContext,
                IClassroomRepository classroomRepository, IMapper mapper,
                UserManager<ApplicationUser> userManager, IMemberRepository memberRepository
                , IServantRepository servantRepository, IMeetingRepository meetingRepository,
                IOptions<ServantProfileOptions> servantProfileOptions,
                IMeetingPublicIdService meetingPublicIdService,
                ICacheService cache,
                ICacheKeyBuilder cacheKeys,
                ICacheContextAccessor cacheContext)
        {
            _userManager = userManager;
            _classroomRepository = classroomRepository;
            _currentUser = currentUser;
            _tenantContext = tenantContext;
            _mapper = mapper;
            _servantRepo = servantRepository;
            _memberRepo = memberRepository;
            _meetingRepository = meetingRepository;
            _servantProfileOptions = servantProfileOptions.Value;
            _meetingPublicIdService = meetingPublicIdService;
            _cache = cache;
            _cacheKeys = cacheKeys;
            _cacheContext = cacheContext;

        }

        public async Task<List<SelectOptionDTO>> GetMeetingsForSelection()
        {
            var ctx = _cacheContext.TryGet();
            if (ctx is null || string.IsNullOrWhiteSpace(ctx.Role))
            {
                // If tenant/role cannot be resolved, bypass caching for safety.
                return await LoadMeetingsForSelectionAsync();
            }

            var key = _cacheKeys.TenantRole(ctx.Role!, "events", ("view", "select"));
            return await _cache.GetOrCreateAsync(
                key,
                new CacheEntryOptions(CacheTtls.Events),
                ctx,
                _ => LoadMeetingsForSelectionAsync());
        }

        private async Task<List<SelectOptionDTO>> LoadMeetingsForSelectionAsync()
        {
            var appUser = await RequireCurrentUserAsync();

            List<Meeting> meetings;

            if (_currentUser.IsInRole("SuperAdmin"))
            {
                var churchId = ResolveSuperAdminChurchId(appUser);
                meetings = await _meetingRepository.GetByChurchIdAsync(churchId);
            }
            else if (_currentUser.IsInRole("Admin"))
            {
                if (appUser.MeetingId == null)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Meeting"] = new[] { "Admin is not assigned to a meeting." }
                    });

                var meeting = await _meetingRepository.GetByIdAsync(appUser.MeetingId.Value);
                meetings = meeting != null ? new List<Meeting> { meeting } : new List<Meeting>();
            }
            else if (_currentUser.IsInRole("Servant"))
            {
                var servant = await _servantRepo.EnsureServantProfileAsync(
                    appUser,
                    _servantProfileOptions.AutoCreateMissingProfile);

                if (servant == null)
                {
                    var detail = _servantProfileOptions.AutoCreateMissingProfile
                        ? ServantProfileMessages.MissingAfterAutoCreateAttempt()
                        : ServantProfileMessages.MissingProfileManual();
                    throw new ServantProfileMissingException(detail);
                }

                if (servant.MeetingId == null)
                    meetings = new List<Meeting>();
                else
                {
                    var meeting = await _meetingRepository.GetByIdAsync(servant.MeetingId.Value);
                    meetings = meeting != null ? new List<Meeting> { meeting } : new List<Meeting>();
                }
            }
            else
            {
                throw new UnauthorizedAccessException("User role is not allowed.");
            }

            return meetings
                .Select(m => new SelectOptionDTO
                {
                    Id = m.Id,
                    Name = m.Name ?? string.Empty
                })
                .ToList();
        }

        public async Task<List<MeetingReadDTO>> GetVisibleMeetings()
        {

            var ctx = _cacheContext.TryGet();
            if (ctx is null || string.IsNullOrWhiteSpace(ctx.Role))
            {
                return await LoadVisibleMeetingsAsync();
            }

            var key = _cacheKeys.TenantRole(ctx.Role!, "events", ("view", "visible"));
            return await _cache.GetOrCreateAsync(
                key,
                new CacheEntryOptions(CacheTtls.Events),
                ctx,
                _ => LoadVisibleMeetingsAsync());
        }

        private async Task<List<MeetingReadDTO>> LoadVisibleMeetingsAsync()
        {
            var appUser = await RequireCurrentUserAsync();

            List<Meeting> meetings;

            if (_currentUser.IsInRole("SuperAdmin"))
            {
                var churchId = ResolveSuperAdminChurchId(appUser);
                meetings = await _meetingRepository.GetByChurchIdAsync(churchId);
            }
            else if (_currentUser.IsInRole("Admin"))
            {
                if (appUser.MeetingId == null)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Meeting"] = new[] { "Admin is not assigned to a meeting." }
                    });

                var meeting = await _meetingRepository.GetByIdAsync(appUser.MeetingId.Value);
                meetings = meeting != null ? new List<Meeting> { meeting } : new List<Meeting>();
            }
            else if (_currentUser.IsInRole("Servant"))
            {
                var servant = await _servantRepo.EnsureServantProfileAsync(
                    appUser,
                    _servantProfileOptions.AutoCreateMissingProfile);

                if (servant == null)
                {
                    var detail = _servantProfileOptions.AutoCreateMissingProfile
                        ? ServantProfileMessages.MissingAfterAutoCreateAttempt()
                        : ServantProfileMessages.MissingProfileManual();
                    throw new ServantProfileMissingException(detail);
                }

                if (servant.MeetingId == null)
                    meetings = new List<Meeting>();
                else
                {
                    var meeting = await _meetingRepository.GetByIdAsync(servant.MeetingId.Value);
                    meetings = meeting != null ? new List<Meeting> { meeting } : new List<Meeting>();
                }
            }
            else
            {
                throw new UnauthorizedAccessException("User role is not allowed.");
            }

            var dtos = _mapper.Map<List<MeetingReadDTO>>(meetings);
            foreach (var dto in dtos)
                dto.PublicId = string.Empty;

            return dtos;
        }

        public async Task AddMeeting(MeetingAddDTO meeting)
        {
            var model = _mapper.Map<Meeting>(meeting);

            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing");

            model.ChurchId = churchId;
            model.PublicId = await _meetingPublicIdService.GenerateUniqueAsync(churchId);
            await  _meetingRepository.AddAsync(model);

            var ctx = _cacheContext.TryGet();
            if (ctx is not null)
            {
                await _cache.RemoveTenantSegmentAsync("events", ctx);
                await _cache.RemoveTenantSegmentAsync("dashboard", ctx);
            }
        }

        public async Task UpdateMeeting(int id, MeetingUpdateDto dto, bool generateDefaults = false)
        {
            if (id <= 0)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["MeetingId"] = new[] { "Meeting id must be a positive integer." }
                });

            var meeting = await _meetingRepository.GetByIdAsync(id);
            if (meeting == null)
                throw new NotFoundException($"Meeting with id {id} not found.");

            await EnsureCanModifyMeetingAsync(meeting);

            if (dto.Name != null)
                meeting.Name = dto.Name.Trim();
            else if (generateDefaults && string.IsNullOrWhiteSpace(meeting.Name))
                meeting.Name = $"Meeting {meeting.Id}";

            if (dto.WeeklyAppointment.HasValue)
                meeting.Weekly_appointment = dto.WeeklyAppointment.Value;

            if (dto.DayOfWeek != null)
                meeting.DayOfWeek = dto.DayOfWeek.Trim();

            // allow explicitly clearing leader by setting null
            meeting.LeaderServantId = dto.LeaderServantId;

            await _meetingRepository.UpdateAsync(meeting);

            var ctx = _cacheContext.TryGet();
            if (ctx is not null)
            {
                await _cache.RemoveTenantSegmentAsync("events", ctx);
                await _cache.RemoveTenantSegmentAsync("dashboard", ctx);
            }
        }

        public async Task DeleteMeetingAsync(int id)
        {
            if (id <= 0)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["MeetingId"] = new[] { "Meeting id must be a positive integer." }
                });

            if (!_currentUser.IsInRole("SuperAdmin"))
                throw new UnauthorizedAccessException("Only Church Super Admin can delete meetings.");

            var appUser = await RequireCurrentUserAsync();
            var churchId = ResolveSuperAdminChurchId(appUser);

            var meeting = await _meetingRepository.GetByIdAsync(id);
            if (meeting == null)
                throw new NotFoundException($"Meeting with id {id} not found.");

            if (meeting.ChurchId != churchId)
                throw new UnauthorizedAccessException("This meeting does not belong to your church.");

            await _meetingRepository.DeleteWithDependenciesAsync(id);

            var ctx = _cacheContext.TryGet();
            if (ctx is not null)
            {
                await _cache.RemoveTenantSegmentAsync("events", ctx);
                await _cache.RemoveTenantSegmentAsync("dashboard", ctx);
            }
        }

        private async Task<ApplicationUser> RequireCurrentUserAsync()
        {
            if (!_currentUser.IsAuthenticated || string.IsNullOrEmpty(_currentUser.UserId))
                throw new UnauthorizedAccessException("User is not authenticated.");

            var appUser = await _userManager.FindByIdAsync(_currentUser.UserId);
            if (appUser == null)
                throw new NotFoundException("User not found.");

            return appUser;
        }

        /// <summary>
        /// Super Admin flows (pending users, create meeting) scope by JWT <see cref="ITenantContext.ChurchId"/>.
        /// Fall back to the persisted user row when the claim is absent.
        /// </summary>
        private int ResolveSuperAdminChurchId(ApplicationUser appUser)
        {
            var churchId = _tenantContext.ChurchId ?? appUser.ChurchId;
            if (churchId is null or <= 0)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Church"] = new[] { "Pastor is not assigned to a church." }
                });
            }

            return churchId.Value;
        }

        private async Task EnsureCanModifyMeetingAsync(Meeting meeting)
        {
            var appUser = await RequireCurrentUserAsync();

            if (_currentUser.IsInRole("SuperAdmin"))
            {
                var churchId = ResolveSuperAdminChurchId(appUser);
                if (meeting.ChurchId != churchId)
                {
                    throw new UnauthorizedAccessException(
                        "This meeting does not belong to your church.");
                }

                return;
            }

            if (_currentUser.IsInRole("Admin"))
            {
                if (appUser.MeetingId != meeting.Id)
                {
                    throw new UnauthorizedAccessException(
                        "You can only edit the meeting you manage.");
                }

                return;
            }

            throw new UnauthorizedAccessException("You are not allowed to edit this meeting.");
        }
    }
}
