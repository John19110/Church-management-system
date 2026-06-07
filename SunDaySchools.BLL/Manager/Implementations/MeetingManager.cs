using AutoMapper;
using Microsoft.AspNetCore.Identity;
using SunDaySchools.BLL.Abstractions;
using SunDaySchools.DAL.Abstractions;
using Microsoft.Extensions.Options;
using SunDaySchools.BLL.Configuration;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.Meeting;
using SunDaySchools.BLL.DTOS.MeetingDtos;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace SunDaySchools.BLL.Manager.Implementations
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


        public MeetingManager(ICurrentUserContext currentUser,
                ITenantContext tenantContext,
                IClassroomRepository classroomRepository, IMapper mapper,
                UserManager<ApplicationUser> userManager, IMemberRepository memberRepository
                , IServantRepository servantRepository, IMeetingRepository meetingRepository,
                IOptions<ServantProfileOptions> servantProfileOptions)
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

        }

        public async Task<List<SelectOptionDTO>> GetMeetingsForSelection()
        {
            var appUser = await RequireCurrentUserAsync();

            List<Meeting> meetings;

            if (_currentUser.IsInRole("SuperAdmin"))
            {
                if (appUser.ChurchId == null)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Church"] = new[] { "Pastor is not assigned to a church." }
                    });

                meetings = await _meetingRepository.GetByChurchIdAsync(appUser.ChurchId.Value);
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

            var appUser = await RequireCurrentUserAsync();

            List<Meeting> meetings;

            if (_currentUser.IsInRole("SuperAdmin"))
            {
                if (appUser.ChurchId == null)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Church"] = new[] { "Pastor is not assigned to a church." }
                    });

                meetings = await _meetingRepository.GetByChurchIdAsync(appUser.ChurchId.Value);
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

            return _mapper.Map<List<MeetingReadDTO>>(meetings);

        }

        public async Task AddMeeting(MeetingAddDTO meeting)
        {
            var model = _mapper.Map<Meeting>(meeting);

            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing");

            model.ChurchId = churchId;
            await  _meetingRepository.AddAsync(model);
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
    }
}
