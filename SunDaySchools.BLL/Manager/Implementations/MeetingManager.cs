using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchoolsDAL.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class MeetingManager
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
    }
}
