using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.ClsssroomDtos;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Repository.Implementations;
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
   

        public class ClassroomManager : IClassroomManager
        {


            private readonly IClassroomRepository         _classroomRepository;
            private readonly IHttpContextAccessor         _httpContextAccessor;
            private readonly IServantRepository           _servantRepo;
            private readonly IMemberRepository            _memberRepo;
            private readonly IMapper                      _mapper;
            private readonly UserManager<ApplicationUser> _userManager;
            private readonly IMeetingRepository           _meetingRepository;


        public ClassroomManager(IHttpContextAccessor httpContextAccessor, 
                IClassroomRepository classroomRepository,IMapper mapper,
                UserManager<ApplicationUser> userManager,IMemberRepository memberRepository
                ,IServantRepository servantRepository, IMeetingRepository meetingRepository)
            {
            _userManager = userManager;
            _classroomRepository = classroomRepository;
            _httpContextAccessor = httpContextAccessor;
            _mapper = mapper;
            _servantRepo = servantRepository;
            _memberRepo = memberRepository;
            _meetingRepository = meetingRepository;


            }
        // ClassroomReadDTO
        public async Task<List<ClassroomReadDTO>> GetVisibleClassrooms(int? meetingId = null)
        {
            var user = _httpContextAccessor.HttpContext?.User;
            if (user == null)
                throw new UnauthorizedAccessException("User is not authenticated.");

            // Resolves user id from principal (JwtBearer maps JWT "sub" to what Identity expects).
            var userIdClaim = _userManager.GetUserId(user);

            if (string.IsNullOrEmpty(userIdClaim))
                throw new UnauthorizedAccessException(
                    "User identifier could not be resolved from the token. Ensure the JWT includes a 'sub' claim.");

            var appUser = await _userManager.FindByIdAsync(userIdClaim);
            

            if (appUser == null)
                throw new UnauthorizedAccessException("User not found for the supplied token.");

            List<Classroom> classrooms;

            if (user.IsInRole("SuperAdmin"))
            {
                if (meetingId.HasValue)
                {
                    var meeting = await _meetingRepository.GetByIdAsync(meetingId.Value);
                    if (meeting == null)
                        throw new NotFoundException($"Meeting with id {meetingId.Value} not found.");

                    if (meeting.ChurchId != appUser.ChurchId)
                        throw new UnauthorizedAccessException(
                            "This meeting does not belong to your church.");

                    classrooms = await _classroomRepository.GetByMeetingIdAsync(meetingId.Value);
                }
                else
                {
                    classrooms = await _classroomRepository.GetByChurchIdAsync(appUser.ChurchId);
                }
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
                 var servant = await _servantRepo.GetByApplicationUserIdAsync(userIdClaim);

                if (servant == null)
                    throw new ServantProfileMissingException(
                        "Your account has the Servant role but is not linked to a Servants table row. " +
                        "Link AspNetUsers.Id to Servants.ApplicationUserId (one row per servant user), or complete servant registration.");

                classrooms = await _classroomRepository.GetByServantIdAsync(servant.Id); 
                

            }
            else
            {
                throw new UnauthorizedAccessException("User role is not allowed.");
            }

            return _mapper.Map<List<ClassroomReadDTO>>(classrooms);
        }

        public async Task<List<SelectOptionDTO>> GetClassroomsForSelection()
        {
            var classrooms = await _classroomRepository.GetClassroomsForSelection();

            return classrooms.Select(c => new SelectOptionDTO
            {
                Id = c.Id,
                Name = c.Item2
            }).ToList();
        }

        public async Task AddAsync(ClassroomAddDTO dto)
        {
            var user = _httpContextAccessor.HttpContext?.User;
            if (user == null)
                throw new UnauthorizedAccessException("User is not authenticated.");

            var churchClaim = user.FindFirst("ChurchId");
            if (churchClaim == null)
                throw new UnauthorizedAccessException("ChurchId claim is missing.");

            int churchId = int.Parse(churchClaim.Value);

            var model = _mapper.Map<Classroom>(dto);
            model.ChurchId = churchId;

            if (user.IsInRole("Admin"))
            {
                var meetingClaim = user.FindFirst("MeetingId");
                if (meetingClaim == null)
                    throw new UnauthorizedAccessException("MeetingId claim is missing.");

                model.MeetingId = int.Parse(meetingClaim.Value);
            }
            else if (user.IsInRole("SuperAdmin"))
            {
                if (dto.MeetingId.HasValue)
                {
                    var meeting = await _meetingRepository.GetByIdAsync(dto.MeetingId.Value);

                    if (meeting == null)
                        throw new NotFoundException($"Meeting with id {dto.MeetingId.Value} not found.");

                    if (meeting.ChurchId != churchId)
                        throw new UnauthorizedAccessException("This meeting does not belong to your church.");

                    model.MeetingId = dto.MeetingId.Value;
                }
                else
                {
                    model.MeetingId = null;
                }
            }
            else
            {
                throw new UnauthorizedAccessException("Only Admin or SuperAdmin can add classrooms.");
            }
            // edit here 
            //model.Servants = new List<Servant>();
            //model.Members = new List<Member>();

            if (dto.ServantIds != null && dto.ServantIds.Any())
            {
                var servants = await _servantRepo.GetByIdsAsync(dto.ServantIds);

                var foundIds = servants.Select(s => s.Id).ToHashSet();
                var missingServants = dto.ServantIds.Where(id => !foundIds.Contains(id)).ToList();

                if (missingServants.Any())
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["ServantIds"] = missingServants
                            .Select(id => $"Servant with id {id} was not found.")
                            .ToArray()
                    });
                }

                // edit here 
                //foreach (var servant in servants)
                  //  model.Servants.Add(servant);
            }

            if (dto.MemberIds != null && dto.MemberIds.Any())
            {
                var members = await _memberRepo.GetByIdsAsync(dto.MemberIds);

                var foundIds = members.Select(m => m.Id).ToHashSet();
                var missingMembers = dto.MemberIds.Where(id => !foundIds.Contains(id)).ToList();

                if (missingMembers.Any())
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["MemberIds"] = missingMembers
                            .Select(id => $"Member with id {id} was not found.")
                            .ToArray()
                    });
                }

                foreach (var member in members)
                    model.Members.Add(member);
            }

            await _classroomRepository.AddAsync(model);
            await _classroomRepository.SaveAsync();
        }

    }
}
