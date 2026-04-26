using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
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
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IServantRepository _servantRepo;
        private readonly IMemberRepository _memberRepo;
        private readonly IMapper _mapper;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IMeetingRepository _meetingRepository;
        private readonly ServantProfileOptions _servantProfileOptions;


        public MeetingManager(IHttpContextAccessor httpContextAccessor,
                IClassroomRepository classroomRepository, IMapper mapper,
                UserManager<ApplicationUser> userManager, IMemberRepository memberRepository
                , IServantRepository servantRepository, IMeetingRepository meetingRepository,
                IOptions<ServantProfileOptions> servantProfileOptions)
        {
            _userManager = userManager;
            _classroomRepository = classroomRepository;
            _httpContextAccessor = httpContextAccessor;
            _mapper = mapper;
            _servantRepo = servantRepository;
            _memberRepo = memberRepository;
            _meetingRepository = meetingRepository;
            _servantProfileOptions = servantProfileOptions.Value;

        }

        public async Task<List<SelectOptionDTO>> GetMeetingsForSelection()
        {
            var user = _httpContextAccessor.HttpContext?.User;
            if (user == null)
                throw new UnauthorizedAccessException("User is not authenticated.");

            var userIdClaim = _userManager.GetUserId(user);

            if (string.IsNullOrEmpty(userIdClaim))
                throw new UnauthorizedAccessException(
                    "User identifier could not be resolved from the token.");

            var appUser = await _userManager.FindByIdAsync(userIdClaim);

            if (appUser == null)
                throw new NotFoundException("User not found.");

            List<Meeting> meetings;

            if (user.IsInRole("SuperAdmin"))
            {
                if (appUser.ChurchId == null)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Church"] = new[] { "Pastor is not assigned to a church." }
                    });

                meetings = await _meetingRepository.GetByChurchIdAsync(appUser.ChurchId.Value);
            }
            else if (user.IsInRole("Admin"))
            {
                if (appUser.MeetingId == null)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Meeting"] = new[] { "Admin is not assigned to a meeting." }
                    });

                var meeting = await _meetingRepository.GetByIdAsync(appUser.MeetingId.Value);
                meetings = meeting != null ? new List<Meeting> { meeting } : new List<Meeting>();
            }
            else if (user.IsInRole("Servant"))
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

            var user = _httpContextAccessor.HttpContext?.User;
            if (user == null)
                throw new UnauthorizedAccessException("User is not authenticated.");

            var userIdClaim = _userManager.GetUserId(user);

            if (string.IsNullOrEmpty(userIdClaim))
                throw new UnauthorizedAccessException(
                    "User identifier could not be resolved from the token.");

            var appUser = await _userManager.FindByIdAsync(userIdClaim);

            if (appUser == null)
                throw new NotFoundException("User not found.");

            List<Meeting> meetings;

            if (user.IsInRole("SuperAdmin"))
            {
                if (appUser.ChurchId == null)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Church"] = new[] { "Pastor is not assigned to a church." }
                    });

                meetings = await _meetingRepository.GetByChurchIdAsync(appUser.ChurchId.Value);
            }
            else if (user.IsInRole("Admin"))
            {
                if (appUser.MeetingId == null)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Meeting"] = new[] { "Admin is not assigned to a meeting." }
                    });

                var meeting = await _meetingRepository.GetByIdAsync(appUser.MeetingId.Value);
                meetings = meeting != null ? new List<Meeting> { meeting } : new List<Meeting>();
            }
            else if (user.IsInRole("Servant"))
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

            var claim = _httpContextAccessor.HttpContext?.User?.FindFirst("ChurchId");

            if (claim == null)
                throw new UnauthorizedAccessException("ChurchId claim is missing");

            var churchId = int.Parse(claim.Value);

            model.ChurchId = churchId;
            await  _meetingRepository.AddAsync(model);
        }

        public async Task UpdateMeeting(int id, MeetingUpdateDto dto)
        {
            if (id <= 0)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["MeetingId"] = new[] { "Meeting id must be a positive integer." }
                });

            var meeting = await _meetingRepository.GetByIdAsync(id);
            if (meeting == null)
                throw new NotFoundException($"Meeting with id {id} not found.");

            meeting.LeaderServantId = dto.LeaderServantId;

            await _meetingRepository.UpdateAsync(meeting);
        }


    }
}
