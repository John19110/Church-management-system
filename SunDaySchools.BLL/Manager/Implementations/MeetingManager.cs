using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using SunDaySchools.BLL.DTOS;
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
using System.Security.Claims;
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


        public MeetingManager(IHttpContextAccessor httpContextAccessor,
                IClassroomRepository classroomRepository, IMapper mapper,
                UserManager<ApplicationUser> userManager, IMemberRepository memberRepository
                , IServantRepository servantRepository, IMeetingRepository meetingRepository)
        {
            _userManager = userManager;
            _classroomRepository = classroomRepository;
            _httpContextAccessor = httpContextAccessor;
            _mapper = mapper;
            _servantRepo = servantRepository;
            _memberRepo = memberRepository;
            _meetingRepository = meetingRepository;


        }

        public async Task<List<SelectOptionDTO>> GetMeetingsForSelection()
        {
            var meetings = await _meetingRepository.GetAllAsync();

            return meetings.Select(m => new SelectOptionDTO
            {
                Id = m.Id,
                Name = m.Name
            }).ToList();
        }


        public async Task<List<MeetingReadDTO>> GetVisibleMeetings()
        {

            var user = _httpContextAccessor.HttpContext?.User;
            if (user == null)
                throw new UnauthorizedAccessException("User is not authenticated.");

            var userIdClaim = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim))
                throw new UnauthorizedAccessException("UserId claim is missing.");

            var appUser = await _userManager.FindByIdAsync(userIdClaim);

            if (appUser == null)
                throw new NotFoundException("User not found.");

            List<Meeting> meetings;

            if (!user.IsInRole("SuperAdmin"))
            {
                throw new UnauthorizedAccessException("User is not authenticated.");
            }
            else
            {
                if (appUser.ChurchId == null)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Church"] = new[] { "Pasotr is not assigned to a Church." }
                    });

                meetings = await _meetingRepository.GetByChurchIdAsync(appUser.ChurchId.Value);
            } 
           
         

            return _mapper.Map<List<MeetingReadDTO>>(meetings);

        }

    }
}
