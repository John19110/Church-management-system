using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using AutoMapper;

namespace SunDaySchools.BLL.Manager.Implementations
{
   

        public class ClassroomService : IClassroomManager
        {
            private readonly IClassroomRepository _classroomRepository;
            private readonly IHttpContextAccessor _httpContextAccessor;
            private readonly IMapper _mapper;
                             
            public ClassroomService(IHttpContextAccessor httpContextAccessor, 
                IClassroomRepository classroomRepository,IMapper mapper )
            {
                _classroomRepository = classroomRepository;
            _httpContextAccessor = httpContextAccessor;
            _mapper = mapper;
            }
        // ClassroomReadDTO
        public async Task<List<ClassroomReadDTO>> GetVisibleClassrooms()
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

            List<Classroom> classrooms;

            if (user.IsInRole("SuperAdmin"))
            {
                classrooms = await _classroomRepository.GetByChurchIdAsync(appUser.ChurchId);
            }
            else if (user.IsInRole("Admin"))
            {
                if (appUser.MeetingId == null)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Meeting"] = new[] { "Admin is not assigned to a meeting." }
                    });

                classrooms = await _classroomRepository.GetByMeetingIdAsync(appUser.MeetingId.Value);
            }
            else if (user.IsInRole("Servant"))
            {
                if (appUser.ServantId == null)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Servant"] = new[] { "Current user is not linked to a servant record." }
                    });

                classrooms = await _classroomRepository.GetByServantIdAsync(appUser.ServantId.Value);
            }
            else
            {
                throw new UnauthorizedAccessException("User role is not allowed.");
            }

            return _mapper.Map<List<ClassroomReadDTO>>(classrooms);
        }
    }
}
