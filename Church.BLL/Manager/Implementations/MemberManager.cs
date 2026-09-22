using AutoMapper;
using Microsoft.AspNetCore.Identity;
using Church.BLL.Abstractions;
using Church.BLL.Abstractions.Caching;
using Microsoft.Extensions.Options;
using Church.BLL.Configuration;
using Church.BLL.DTOS;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;
using Church.BLL.Services;
using Church.DAL.Abstractions;
using Church.DAL.Repository.Interfaces;
using Church.DAL.Models;
using Church.Domain;
using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;

namespace Church.BLL.Manager.Implementations
{
    public class MemberManager : IMemberManager
    {
        private readonly IMemberRepository _memberRepository;
        private readonly IClassroomRepository _classroomRepository;
        private readonly IMeetingRepository _meetingRepository;
        private readonly IServantRepository _servantRepository;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IMapper _mapper;
        private readonly ICurrentUserContext _currentUser;
        private readonly ITenantContext _tenantContext;
        private readonly ServantProfileOptions _servantProfileOptions;
        private readonly ICacheService _cache;
        private readonly ICacheKeyBuilder _cacheKeys;
        private readonly ICacheContextAccessor _cacheContext;


        public MemberManager(
            IMemberRepository memberRepository,
            IMapper mapper,
            ICurrentUserContext currentUser,
            ITenantContext tenantContext,
            UserManager<ApplicationUser> userManager,
            IClassroomRepository classroomRepository,
            IMeetingRepository meetingRepository,
            IServantRepository servantRepository,
            IOptions<ServantProfileOptions> servantProfileOptions,
            ICacheService cache,
            ICacheKeyBuilder cacheKeys,
            ICacheContextAccessor cacheContext)
        {
            _memberRepository = memberRepository;
            _mapper = mapper;
            _currentUser = currentUser;
            _tenantContext = tenantContext;
            _userManager = userManager;
            _classroomRepository = classroomRepository;
            _meetingRepository = meetingRepository;
            _servantRepository = servantRepository;
            _servantProfileOptions = servantProfileOptions.Value;
            _cache = cache;
            _cacheKeys = cacheKeys;
            _cacheContext = cacheContext;
        }

        public async Task<IEnumerable<MemberReadDTO>> GetAllAsync()
        {
            var ctx = _cacheContext.TryGet();
            if (ctx is null || string.IsNullOrWhiteSpace(ctx.Role))
            {
                var raw = await _memberRepository.GetAllAsync();
                return _mapper.Map<IEnumerable<MemberReadDTO>>(raw);
            }

            var key = _cacheKeys.TenantRole(ctx.Role!, "member-list", ("scope", "all"));
            return await _cache.GetOrCreateAsync(
                key,
                new CacheEntryOptions(CacheTtls.Dashboard),
                ctx,
                async _ =>
                {
                    var raw = await _memberRepository.GetAllAsync();
                    return _mapper.Map<List<MemberReadDTO>>(raw);
                });
        }

        public async Task<MemberReadDTO?> GetByIdAsync(int id)
        {
            var ctx = _cacheContext.TryGet();
            if (ctx is null)
            {
                var member = await LoadMemberForReadAsync(id);
                return member == null ? null : _mapper.Map<MemberReadDTO>(member);
            }

            var key = _cacheKeys.Tenant("members", ("id", id));
            return await _cache.GetOrCreateAsync(
                key,
                new CacheEntryOptions(CacheTtls.Dashboard),
                ctx,
                async _ =>
                {
                    var member = await LoadMemberForReadAsync(id);
                    return member == null ? null : _mapper.Map<MemberReadDTO>(member);
                });
        }

        public async Task<IEnumerable<MemberReadDTO>> GetSpecificClassroomAsync(int classroomId)
        {
            var exists = await _classroomRepository.ExistsAsync(classroomId);
            if (!exists)
                throw new NotFoundException($"Classroom with id {classroomId} was not found.");

            var ctx = _cacheContext.TryGet();
            if (ctx is null || string.IsNullOrWhiteSpace(ctx.Role))
            {
                var raw = await _memberRepository.GetSpecificClassroomAsync(classroomId);
                return _mapper.Map<IEnumerable<MemberReadDTO>>(raw);
            }

            var key = _cacheKeys.TenantRole(ctx.Role!, "member-list", ("classroomId", classroomId));
            return await _cache.GetOrCreateAsync(
                key,
                new CacheEntryOptions(CacheTtls.Dashboard),
                ctx,
                async _ =>
                {
                    var raw = await _memberRepository.GetSpecificClassroomAsync(classroomId);
                    return _mapper.Map<List<MemberReadDTO>>(raw);
                });
        }

        public async Task<IEnumerable<MemberReadDTO>> GetByMeetingIdAsync(int meetingId)
        {
            await RequireAccessibleMeetingAsync(meetingId);
            // Default meeting members list stays assigned-scoped for servants.
            // All-members access is only via GetAllMembersByMeetingIdAsync.
            return await LoadAssignedMeetingMembersCachedAsync(meetingId);
        }

        public async Task<IEnumerable<MemberReadDTO>> GetAllMembersByMeetingIdAsync(int meetingId)
        {
            var meeting = await RequireAccessibleMeetingAsync(meetingId);
            await EnsureCanViewAllMeetingMembersAsync(meeting);
            return await LoadAllMeetingMembersCachedAsync(meeting);
        }

        public async Task<IEnumerable<MemberReadDTO>> GetAssignedByMeetingIdAsync(int meetingId)
        {
            await RequireAccessibleMeetingAsync(meetingId);
            return await LoadAssignedMeetingMembersCachedAsync(meetingId);
        }

        private async Task EnsureCanViewAllMeetingMembersAsync(Meeting meeting)
        {
            if (_currentUser.IsInRole("SuperAdmin") || _currentUser.IsInRole("Admin"))
                return;

            if (!_currentUser.IsInRole("Servant"))
                throw new UnauthorizedAccessException("User role is not allowed.");

            if (meeting.MemberViewMode != MemberViewMode.AllAndAssigned)
            {
                throw new UnauthorizedAccessException(
                    "All members view is not enabled for this meeting.");
            }

            var appUser = await RequireCurrentUserAsync();
            var servant = await _servantRepository.EnsureServantProfileAsync(
                appUser,
                _servantProfileOptions.AutoCreateMissingProfile);

            if (servant == null)
                throw new UnauthorizedAccessException("Servant profile was not found.");

            var allowed = await _meetingRepository.IsServantAllMembersViewerAsync(
                meeting.Id,
                servant.Id);

            if (!allowed)
            {
                throw new UnauthorizedAccessException(
                    "You are not permitted to view all members for this meeting.");
            }
        }

        private async Task<bool> CanCurrentServantViewAllMembersAsync(Meeting meeting)
        {
            if (meeting.MemberViewMode != MemberViewMode.AllAndAssigned)
                return false;

            if (!_currentUser.IsInRole("Servant"))
                return _currentUser.IsInRole("Admin") || _currentUser.IsInRole("SuperAdmin");

            var appUser = await RequireCurrentUserAsync();
            var servant = await _servantRepository.EnsureServantProfileAsync(
                appUser,
                _servantProfileOptions.AutoCreateMissingProfile);

            if (servant == null)
                return false;

            return await _meetingRepository.IsServantAllMembersViewerAsync(meeting.Id, servant.Id);
        }

        private async Task<IEnumerable<MemberReadDTO>> LoadAssignedMeetingMembersCachedAsync(int meetingId)
        {
            var ctx = _cacheContext.TryGet();
            if (ctx is null || string.IsNullOrWhiteSpace(ctx.Role))
            {
                var raw = await _memberRepository.GetByMeetingIdAsync(meetingId);
                return _mapper.Map<IEnumerable<MemberReadDTO>>(raw);
            }

            var key = _cacheKeys.TenantRole(
                ctx.Role!,
                "member-list",
                ("meetingId", meetingId),
                ("view", "assigned"));
            return await _cache.GetOrCreateAsync(
                key,
                new CacheEntryOptions(CacheTtls.Dashboard),
                ctx,
                async _ =>
                {
                    var raw = await _memberRepository.GetByMeetingIdAsync(meetingId);
                    return _mapper.Map<List<MemberReadDTO>>(raw);
                });
        }

        private async Task<IEnumerable<MemberReadDTO>> LoadAllMeetingMembersCachedAsync(Meeting meeting)
        {
            var churchId = meeting.ChurchId;
            var meetingId = meeting.Id;
            var ctx = _cacheContext.TryGet();
            if (ctx is null || string.IsNullOrWhiteSpace(ctx.Role))
            {
                var raw = await _memberRepository.GetAllByMeetingForTenantAsync(churchId, meetingId);
                return _mapper.Map<IEnumerable<MemberReadDTO>>(raw);
            }

            var key = _cacheKeys.TenantRole(
                ctx.Role!,
                "member-list",
                ("meetingId", meetingId),
                ("view", "all"));
            return await _cache.GetOrCreateAsync(
                key,
                new CacheEntryOptions(CacheTtls.Dashboard),
                ctx,
                async _ =>
                {
                    var raw = await _memberRepository.GetAllByMeetingForTenantAsync(churchId, meetingId);
                    return _mapper.Map<List<MemberReadDTO>>(raw);
                });
        }

        private async Task<Meeting> RequireAccessibleMeetingAsync(int meetingId)
        {
            if (meetingId <= 0)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["MeetingId"] = new[] { "Meeting id must be a positive integer." }
                });
            }

            var meeting = await _meetingRepository.GetByIdAsync(meetingId);
            if (meeting == null)
                throw new NotFoundException($"Meeting with id {meetingId} was not found.");

            await EnsureCallerCanAccessMeetingAsync(meeting);
            return meeting;
        }

        private async Task EnsureCallerCanAccessMeetingAsync(Meeting meeting)
        {
            if (_currentUser.IsInRole("SuperAdmin"))
            {
                if (_tenantContext.ChurchId.HasValue && meeting.ChurchId != _tenantContext.ChurchId.Value)
                    throw new UnauthorizedAccessException("You can only access meetings in your church.");
                return;
            }

            if (_currentUser.IsInRole("Admin"))
            {
                var appUser = await RequireCurrentUserAsync();
                if (appUser.MeetingId == null || appUser.MeetingId.Value != meeting.Id)
                    throw new UnauthorizedAccessException("You can only access members in your assigned meeting.");
                return;
            }

            if (_currentUser.IsInRole("Servant"))
            {
                var appUser = await RequireCurrentUserAsync();
                var servant = await _servantRepository.EnsureServantProfileAsync(
                    appUser,
                    _servantProfileOptions.AutoCreateMissingProfile);

                if (servant == null || servant.MeetingId == null || servant.MeetingId.Value != meeting.Id)
                    throw new UnauthorizedAccessException("You can only access members in your assigned meeting.");
                return;
            }

            throw new UnauthorizedAccessException("User role is not allowed.");
        }

        private async Task<Member?> LoadMemberForReadAsync(int id)
        {
            var member = await _memberRepository.GetByIdAsync(id);
            if (member != null)
                return member;

            // Selected all-members viewers may open members outside assigned classrooms.
            if (!_currentUser.IsInRole("Servant"))
                return null;

            var unfiltered = await _memberRepository.GetByIdIgnoringFiltersAsync(id);
            if (unfiltered == null)
                return null;

            if (!_tenantContext.ChurchId.HasValue || unfiltered.ChurchId != _tenantContext.ChurchId.Value)
                return null;

            if (unfiltered.MeetingId is not int memberMeetingId || memberMeetingId <= 0)
                return null;

            var meeting = await _meetingRepository.GetByIdAsync(memberMeetingId);
            if (meeting == null)
                return null;

            await EnsureCallerCanAccessMeetingAsync(meeting);

            if (!await CanCurrentServantViewAllMembersAsync(meeting))
                return null;

            return unfiltered;
        }

        private async Task<ApplicationUser> RequireCurrentUserAsync()
        {
            if (!_currentUser.IsAuthenticated || string.IsNullOrEmpty(_currentUser.UserId))
                throw new UnauthorizedAccessException("User is not authenticated.");

            var appUser = await _userManager.FindByIdAsync(_currentUser.UserId);
            if (appUser == null)
                throw new UnauthorizedAccessException("User not found.");

            return appUser;
        }

        public async Task<int> AddAsync(
            MemberAddDTO memberDto,
            int? classroomId = null,
            int? meetingId = null)
        {
            if (!_currentUser.IsAuthenticated || string.IsNullOrEmpty(_currentUser.UserId))
                throw new UnauthorizedAccessException("User is not authenticated.");

            var appUser = await _userManager.FindByIdAsync(_currentUser.UserId);
            if (appUser == null)
                throw new NotFoundException("User not found.");

            if (classroomId is > 0)
                return await AddToClassroomAsync(memberDto, appUser, classroomId.Value, meetingId);

            if (meetingId is > 0)
                return await AddToMeetingAsync(memberDto, appUser, meetingId.Value);

            throw new ValidationException(new Dictionary<string, string[]>
            {
                ["meetingId"] = new[]
                {
                    "Either classroomId or meetingId is required to add a member."
                }
            });
        }

        private async Task<int> AddToMeetingAsync(
            MemberAddDTO memberDto,
            ApplicationUser appUser,
            int meetingId)
        {
            var meeting = await _meetingRepository.GetByIdAsync(meetingId);
            if (meeting == null)
                throw new NotFoundException($"Meeting with id {meetingId} was not found.");

            if (meeting.ChurchId != appUser.ChurchId)
                throw new UnauthorizedAccessException("This meeting does not belong to your church.");

            if (meeting.HasClassrooms)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["ClassroomId"] = new[]
                    {
                        "This meeting uses classrooms. Assign the member to a classroom."
                    }
                });
            }

            await EnsureCanAddMemberToMeetingAsync(appUser, meeting);

            var model = await MapNewMemberAsync(memberDto);
            model.ClassroomId = null;
            model.MeetingId = meeting.Id;
            model.ChurchId = meeting.ChurchId;

            await _memberRepository.AddAsync(model);
            await InvalidateMemberCachesAsync();
            return model.Id;
        }

        private async Task<int> AddToClassroomAsync(
            MemberAddDTO memberDto,
            ApplicationUser appUser,
            int classroomId,
            int? expectedMeetingId)
        {
            var classroom = await _classroomRepository.GetByIdAsync(classroomId);
            if (classroom == null)
                throw new NotFoundException($"Classroom with id {classroomId} was not found.");

            if (classroom.ChurchId != appUser.ChurchId)
                throw new UnauthorizedAccessException("This classroom does not belong to your church.");

            if (classroom.MeetingId is null or <= 0)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["ClassroomId"] = new[] { "This classroom is not assigned to a meeting." }
                });
            }

            var meeting = await _meetingRepository.GetByIdAsync(classroom.MeetingId.Value);
            if (meeting == null)
                throw new NotFoundException($"Meeting with id {classroom.MeetingId.Value} was not found.");

            if (!meeting.HasClassrooms)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["ClassroomId"] = new[]
                    {
                        "This meeting does not use classrooms. Add the member to the meeting instead."
                    }
                });
            }

            if (expectedMeetingId.HasValue)
            {
                if (expectedMeetingId.Value <= 0)
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["meetingId"] = new[] { "Meeting id must be a positive integer." }
                    });
                }

                if (classroom.MeetingId != expectedMeetingId.Value)
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["ClassroomId"] = new[]
                        {
                            "The selected classroom does not belong to the specified meeting."
                        }
                    });
                }
            }

            if (_currentUser.IsInRole("Servant"))
            {
                var servant = await _servantRepository.EnsureServantProfileAsync(
                    appUser,
                    _servantProfileOptions.AutoCreateMissingProfile);
                if (servant == null)
                {
                    var detail = _servantProfileOptions.AutoCreateMissingProfile
                        ? ServantProfileMessages.MissingAfterAutoCreateAttempt()
                        : ServantProfileMessages.MissingProfileManual();
                    throw new ServantProfileMissingException(detail);
                }

                var isAssigned =
                    await _classroomRepository.IsServantAssignedAsync(servant.Id, classroomId);
                if (!isAssigned)
                    throw new UnauthorizedAccessException("This class is not assigned to you.");
            }
            else if (_currentUser.IsInRole("Admin"))
            {
                if (appUser.MeetingId == null)
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Meeting"] = new[] { "Admin is not assigned to a meeting." }
                    });
                }

                if (classroom.MeetingId != appUser.MeetingId)
                    throw new UnauthorizedAccessException(
                        "You can only add members to classrooms in your assigned meeting.");
            }
            else if (!_currentUser.IsInRole("SuperAdmin"))
            {
                throw new UnauthorizedAccessException("User role is not allowed to add members.");
            }

            var model = await MapNewMemberAsync(memberDto);
            model.ClassroomId = classroomId;
            model.MeetingId = classroom.MeetingId;
            model.ChurchId = classroom.ChurchId;

            await _memberRepository.AddAsync(model);
            await InvalidateMemberCachesAsync();
            return model.Id;
        }

        private async Task EnsureCanAddMemberToMeetingAsync(ApplicationUser appUser, Meeting meeting)
        {
            if (_currentUser.IsInRole("Servant"))
            {
                var servant = await _servantRepository.EnsureServantProfileAsync(
                    appUser,
                    _servantProfileOptions.AutoCreateMissingProfile);
                if (servant == null)
                {
                    var detail = _servantProfileOptions.AutoCreateMissingProfile
                        ? ServantProfileMessages.MissingAfterAutoCreateAttempt()
                        : ServantProfileMessages.MissingProfileManual();
                    throw new ServantProfileMissingException(detail);
                }

                if (servant.MeetingId != meeting.Id)
                    throw new UnauthorizedAccessException(
                        "You can only add members to your assigned meeting.");
            }
            else if (_currentUser.IsInRole("Admin"))
            {
                if (appUser.MeetingId == null)
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Meeting"] = new[] { "Admin is not assigned to a meeting." }
                    });
                }

                if (appUser.MeetingId != meeting.Id)
                    throw new UnauthorizedAccessException(
                        "You can only add members to your assigned meeting.");
            }
            else if (!_currentUser.IsInRole("SuperAdmin"))
            {
                throw new UnauthorizedAccessException("User role is not allowed to add members.");
            }
        }

        private async Task<Member> MapNewMemberAsync(MemberAddDTO memberDto)
        {
            string? fileName = null;

            if (memberDto.Image != null)
            {
                var extension = await ImageUploadValidator
                    .ValidateAndGetExtensionAsync(memberDto.Image);

                fileName = Guid.NewGuid().ToString() + extension;

                var folderPath = Path.Combine("wwwroot", "images");
                Directory.CreateDirectory(folderPath);

                var filePath = Path.Combine(folderPath, fileName);

                using var stream = new FileStream(filePath, FileMode.Create);
                await memberDto.Image.CopyToAsync(stream);
            }

            var model = _mapper.Map<Member>(memberDto);
            model.ImageFileName = fileName;
            model.ImageUrl = fileName != null ? $"/images/{fileName}" : null;
            return model;
        }

        private async Task InvalidateMemberCachesAsync()
        {
            var ctx = _cacheContext.TryGet();
            if (ctx is not null)
            {
                await _cache.RemoveTenantSegmentAsync("member-list", ctx);
                await _cache.RemoveTenantSegmentAsync("dashboard", ctx);
                await _cache.RemoveTenantSegmentAsync("statistics", ctx);
            }
        }
        public async Task<List<SelectOptionDTO>> GetMembersForSelection()
        {
            var ctx = _cacheContext.TryGet();
            if (ctx is null || string.IsNullOrWhiteSpace(ctx.Role))
            {
                var raw = await _memberRepository.GetMembersForSelection();
                return raw.Select(m => new SelectOptionDTO { Id = m.Id, Name = m.Item2 }).ToList();
            }

            var key = _cacheKeys.TenantRole(ctx.Role!, "member-list", ("view", "select"));
            return await _cache.GetOrCreateAsync(
                key,
                new CacheEntryOptions(CacheTtls.Dashboard),
                ctx,
                async _ =>
                {
                    var raw = await _memberRepository.GetMembersForSelection();
                    return raw.Select(m => new SelectOptionDTO { Id = m.Id, Name = m.Item2 }).ToList();
                });
        }
        public async Task UpdateAsync(MemberUpdateDTO memberUpdateDto)
        {
            var existing = await _memberRepository.GetByIdAsync(memberUpdateDto.Id);

            if (existing == null)
                throw new NotFoundException($"Member with id {memberUpdateDto.Id} not found.");

            // Partial update: only apply provided fields.
            if (memberUpdateDto.Name1 != null) existing.Name1 = memberUpdateDto.Name1;
            if (memberUpdateDto.Name2 != null) existing.Name2 = memberUpdateDto.Name2;
            if (memberUpdateDto.Name3 != null) existing.Name3 = memberUpdateDto.Name3;
            if (memberUpdateDto.Gender != null) existing.Gender = memberUpdateDto.Gender;
            if (memberUpdateDto.Address != null) existing.Address = memberUpdateDto.Address;

            if (memberUpdateDto.DateOfBirth.HasValue) existing.DateOfBirth = memberUpdateDto.DateOfBirth.Value;
            if (memberUpdateDto.JoiningDate.HasValue) existing.JoiningDate = memberUpdateDto.JoiningDate.Value;
            if (memberUpdateDto.LastAttendanceDate.HasValue) existing.LastAttendanceDate = memberUpdateDto.LastAttendanceDate.Value;
            if (memberUpdateDto.SpiritualDateOfBirth.HasValue) existing.SpiritualDateOfBirth = memberUpdateDto.SpiritualDateOfBirth;

            if (memberUpdateDto.IsDiscipline.HasValue) existing.IsDiscipline = memberUpdateDto.IsDiscipline.Value;
            if (memberUpdateDto.TotalNumberOfDaysAttended.HasValue) existing.TotalNumberOfDaysAttended = memberUpdateDto.TotalNumberOfDaysAttended.Value;

            if (memberUpdateDto.HaveBrothers.HasValue) existing.HaveBrothers = memberUpdateDto.HaveBrothers;
            if (memberUpdateDto.BrothersNames != null) existing.BrothersNames = memberUpdateDto.BrothersNames;
            if (memberUpdateDto.Notes != null) existing.Notes = memberUpdateDto.Notes;
            if (memberUpdateDto.PhoneNumbers != null)
                existing.PhoneNumbers = _mapper.Map<List<MemberContact>>(memberUpdateDto.PhoneNumbers);

            if (memberUpdateDto.ClassroomId.HasValue)
            {
                var newClassroomId = memberUpdateDto.ClassroomId.Value;
                if (newClassroomId <= 0)
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["ClassroomId"] = new[] { "Classroom id must be a positive integer." }
                    });
                }

                var classroom = await _classroomRepository.GetByIdAsync(newClassroomId);
                if (classroom == null)
                    throw new NotFoundException($"Classroom with id {newClassroomId} was not found.");

                if (classroom.ChurchId != existing.ChurchId)
                    throw new UnauthorizedAccessException(
                        "The selected classroom does not belong to this member's church.");

                if (classroom.MeetingId is > 0)
                {
                    var targetMeeting = await _meetingRepository.GetByIdAsync(classroom.MeetingId.Value);
                    if (targetMeeting != null && !targetMeeting.HasClassrooms)
                    {
                        throw new ValidationException(new Dictionary<string, string[]>
                        {
                            ["ClassroomId"] = new[]
                            {
                                "This meeting does not use classrooms."
                            }
                        });
                    }
                }

                if (_currentUser.IsInRole("Admin"))
                {
                    var appUser = await _userManager.FindByIdAsync(_currentUser.UserId!);
                    if (appUser?.MeetingId == null)
                    {
                        throw new ValidationException(new Dictionary<string, string[]>
                        {
                            ["Meeting"] = new[] { "Admin is not assigned to a meeting." }
                        });
                    }

                    if (classroom.MeetingId != appUser.MeetingId)
                        throw new UnauthorizedAccessException(
                            "You can only move members to classrooms in your assigned meeting.");
                }

                existing.ClassroomId = newClassroomId;
                existing.MeetingId = classroom.MeetingId;
            }

            await _memberRepository.UpdateAsync(existing);

            var ctx = _cacheContext.TryGet();
            if (ctx is not null)
            {
                await _cache.RemoveTenantSegmentAsync("member-list", ctx);
                await _cache.RemoveTenantSegmentAsync("members", ctx);
                await _cache.RemoveTenantSegmentAsync("dashboard", ctx);
                await _cache.RemoveTenantSegmentAsync("statistics", ctx);
            }
        }

        public async Task UpdateImageAsync(int id, string imageFileName, string imageUrl)
        {
            var existing = await _memberRepository.GetByIdAsync(id);
            if (existing == null)
                throw new NotFoundException($"Member with id {id} not found.");

            existing.ImageFileName = imageFileName;
            existing.ImageUrl = imageUrl;

            await _memberRepository.UpdateAsync(existing);

            var ctx = _cacheContext.TryGet();
            if (ctx is not null)
            {
                await _cache.RemoveTenantSegmentAsync("member-list", ctx);
                await _cache.RemoveTenantSegmentAsync("members", ctx);
                await _cache.RemoveTenantSegmentAsync("dashboard", ctx);
            }
        }

        public async Task DeleteAsync(int id)
        {
            var member = await _memberRepository.GetByIdAsync(id);

            if (member == null)
                throw new NotFoundException($"Member with id {id} not found.");

            await _memberRepository.DeleteAsync(id);

            var ctx = _cacheContext.TryGet();
            if (ctx is not null)
            {
                await _cache.RemoveTenantSegmentAsync("member-list", ctx);
                await _cache.RemoveTenantSegmentAsync("members", ctx);
                await _cache.RemoveTenantSegmentAsync("dashboard", ctx);
                await _cache.RemoveTenantSegmentAsync("statistics", ctx);
            }
        }
    }
}
