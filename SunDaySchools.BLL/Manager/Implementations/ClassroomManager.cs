using AutoMapper;
using Microsoft.AspNetCore.Identity;
using SunDaySchools.BLL.Abstractions;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.ClsssroomDtos;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Abstractions;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class ClassroomManager : IClassroomManager
    {
        private readonly IClassroomRepository _classroomRepository;
        private readonly ICurrentUserContext _currentUser;
        private readonly ITenantContext _tenantContext;
        private readonly IServantRepository _servantRepo;
        private readonly IMemberRepository _memberRepo;
        private readonly IMapper _mapper;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IMeetingRepository _meetingRepository;

        public ClassroomManager(
            ICurrentUserContext currentUser,
            ITenantContext tenantContext,
            IClassroomRepository classroomRepository,
            IMapper mapper,
            UserManager<ApplicationUser> userManager,
            IMemberRepository memberRepository,
            IServantRepository servantRepository,
            IMeetingRepository meetingRepository)
        {
            _userManager = userManager;
            _classroomRepository = classroomRepository;
            _currentUser = currentUser;
            _tenantContext = tenantContext;
            _mapper = mapper;
            _servantRepo = servantRepository;
            _memberRepo = memberRepository;
            _meetingRepository = meetingRepository;
        }

        public async Task<List<ClassroomReadDTO>> GetVisibleClassrooms(int? meetingId = null)
        {
            var appUser = await RequireCurrentUserAsync();

            List<Classroom> classrooms;

            if (_currentUser.IsInRole("SuperAdmin"))
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
            else if (_currentUser.IsInRole("Admin"))
            {
                if (appUser.MeetingId == null)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Meeting"] = new[] { "Admin is not assigned to a meeting." }
                    });

                classrooms = await _classroomRepository.GetByMeetingIdAsync(appUser.MeetingId.Value);
            }
            else if (_currentUser.IsInRole("Servant"))
            {
                var servant = await _servantRepo.GetByApplicationUserIdAsync(_currentUser.UserId!);

                if (servant == null)
                    throw new ServantProfileMissingException(
                        "Your account has the Servant role but is not linked to a Servants table row. " +
                        "Link AspNetUsers.Id to Servants.ApplicationUserId (one row per servant user), or complete servant registration.");

                classrooms = await _classroomRepository.GetAccessibleForServantAsync(servant.Id);
            }
            else
            {
                throw new UnauthorizedAccessException("User role is not allowed.");
            }

            // Union classrooms where the user is assigned as leader or servant (any role).
            var servantProfile = await _servantRepo.GetByApplicationUserIdAsync(_currentUser.UserId!);
            if (servantProfile != null &&
                (_currentUser.IsInRole("SuperAdmin") || _currentUser.IsInRole("Admin")))
            {
                var assigned = await _classroomRepository.GetAccessibleForServantAsync(servantProfile.Id);
                classrooms = MergeDistinctClassrooms(classrooms, assigned);
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

        public async Task<int> AddAsync(ClassroomAddDTO dto)
        {
            if (!_currentUser.IsAuthenticated)
                throw new UnauthorizedAccessException("User is not authenticated.");

            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing.");

            var model = _mapper.Map<Classroom>(dto);
            model.ChurchId = churchId;

            if (_currentUser.IsInRole("Admin"))
            {
                var meetingId = _tenantContext.MeetingId
                    ?? throw new UnauthorizedAccessException("MeetingId claim is missing.");

                model.MeetingId = meetingId;
            }
            else if (_currentUser.IsInRole("SuperAdmin"))
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

            if (dto.ServantIds != null && dto.ServantIds.Any())
            {
                await ValidateServantIdsExistAsync(dto.ServantIds);
            }

            if (dto.LeaderServantId is > 0)
            {
                var leader = await _servantRepo.GetByIdAsync(dto.LeaderServantId.Value);
                if (leader == null)
                    throw new NotFoundException($"Servant with id {dto.LeaderServantId.Value} not found.");
                model.LeaderServantId = dto.LeaderServantId.Value;
            }

            var desiredServants = BuildDesiredServantIds(dto.ServantIds, model.LeaderServantId);
            if (desiredServants.Count > 0)
                await ValidateServantIdsExistAsync(desiredServants);

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

            if (desiredServants.Count > 0)
            {
                ApplyClassroomServantAssignments(model, desiredServants);
                await _classroomRepository.UpdateAsync(model);
            }

            return model.Id;
        }

        public async Task UpdateAsync(int id, ClassroomUpdateDTO dto, bool generateDefaults = false)
        {
            if (id <= 0)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["ClassroomId"] = new[] { "Classroom id must be a positive integer." }
                });

            if (dto == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Classroom"] = new[] { "The request body cannot be empty." }
                });

            if (dto.Id != 0 && dto.Id != id)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Id"] = new[] { "The ID in the URL does not match the ID in the request body." }
                });

            if (!_currentUser.IsAuthenticated)
                throw new UnauthorizedAccessException("User is not authenticated.");

            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing.");

            var classroom = await _classroomRepository.GetByIdAsync(id);
            if (classroom == null)
                throw new NotFoundException($"Classroom with id {id} not found.");

            if (classroom.ChurchId != churchId)
                throw new UnauthorizedAccessException("This classroom does not belong to your church.");

            if (dto.Name != null)
                classroom.Name = dto.Name.Trim();
            else if (generateDefaults && string.IsNullOrWhiteSpace(classroom.Name))
                classroom.Name = $"Classroom {classroom.Id}";

            if (dto.AgeOfMembers != null)
                classroom.AgeOfMembers = dto.AgeOfMembers.Trim();

            if (_currentUser.IsInRole("Admin"))
            {
                // Admin cannot change meeting; keep as-is
            }
            else if (_currentUser.IsInRole("SuperAdmin"))
            {
                if (dto.MeetingId.HasValue)
                {
                    if (dto.MeetingId.Value <= 0)
                        throw new ValidationException(new Dictionary<string, string[]>
                        {
                            ["MeetingId"] = new[] { "Meeting id must be a positive integer." }
                        });

                    var meeting = await _meetingRepository.GetByIdAsync(dto.MeetingId.Value);
                    if (meeting == null)
                        throw new NotFoundException($"Meeting with id {dto.MeetingId.Value} not found.");
                    if (meeting.ChurchId != churchId)
                        throw new UnauthorizedAccessException("This meeting does not belong to your church.");

                    classroom.MeetingId = dto.MeetingId.Value;
                }
            }
            else
            {
                throw new UnauthorizedAccessException("Only Admin or SuperAdmin can update classrooms.");
            }

            if (dto.LeaderServantId.HasValue)
            {
                if (dto.LeaderServantId.Value <= 0)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["LeaderServantId"] = new[] { "Leader servant id must be a positive integer." }
                    });
                var leader = await _servantRepo.GetByIdAsync(dto.LeaderServantId.Value);
                if (leader == null)
                    throw new NotFoundException($"Servant with id {dto.LeaderServantId.Value} not found.");

                classroom.LeaderServantId = dto.LeaderServantId.Value;
            }

            if (dto.ServantIds is not null)
            {
                var desired = BuildDesiredServantIds(dto.ServantIds, classroom.LeaderServantId);
                await ValidateServantIdsExistAsync(desired);
                ApplyClassroomServantAssignments(classroom, desired);
            }
            else if (dto.LeaderServantId is > 0)
            {
                var desired = BuildDesiredServantIds(null, classroom.LeaderServantId);
                await ValidateServantIdsExistAsync(desired);
                ApplyClassroomServantAssignments(classroom, desired);
            }

            if (dto.MemberIds is not null)
            {
                var desired = dto.MemberIds.Where(x => x > 0).Distinct().ToHashSet();
                var members = await _memberRepo.GetByIdsAsync(desired.ToList());
                var found = members.Select(m => m.Id).ToHashSet();
                var missing = desired.Where(x => !found.Contains(x)).ToList();
                if (missing.Any())
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["MemberIds"] = missing.Select(x => $"Member with id {x} was not found.").ToArray()
                    });

                if (classroom.Members != null)
                {
                    foreach (var m in classroom.Members.Where(m => !desired.Contains(m.Id)).ToList())
                        m.ClassroomId = null;
                }

                foreach (var m in members)
                    m.ClassroomId = classroom.Id;
            }

            await _classroomRepository.UpdateAsync(classroom);
        }

        public async Task DeleteAsync(int id)
        {
            if (id <= 0)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["ClassroomId"] = new[] { "Classroom id must be a positive integer." }
                });

            if (!_currentUser.IsAuthenticated)
                throw new UnauthorizedAccessException("User is not authenticated.");

            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing.");

            var classroom = await _classroomRepository.GetByIdAsync(id);
            if (classroom == null)
                throw new NotFoundException($"Classroom with id {id} not found.");

            if (classroom.ChurchId != churchId)
                throw new UnauthorizedAccessException("This classroom does not belong to your church.");

            if (_currentUser.IsInRole("SuperAdmin"))
            {
                // Church Super Admin may delete any classroom in the church.
            }
            else if (_currentUser.IsInRole("Admin"))
            {
                var appUser = await RequireCurrentUserAsync();
                if (appUser.MeetingId == null)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Meeting"] = new[] { "Admin is not assigned to a meeting." }
                    });

                if (classroom.MeetingId != appUser.MeetingId)
                    throw new UnauthorizedAccessException(
                        "You can only delete classrooms in your assigned meeting.");
            }
            else
            {
                throw new UnauthorizedAccessException(
                    "Only Church Super Admin or Meeting Admin can delete classrooms.");
            }

            await _classroomRepository.DeleteWithDependenciesAsync(id);
        }

        private async Task<ApplicationUser> RequireCurrentUserAsync()
        {
            if (!_currentUser.IsAuthenticated || string.IsNullOrEmpty(_currentUser.UserId))
                throw new UnauthorizedAccessException(
                    "User identifier could not be resolved from the token. Ensure the JWT includes a 'sub' claim.");

            var appUser = await _userManager.FindByIdAsync(_currentUser.UserId);
            if (appUser == null)
                throw new UnauthorizedAccessException("User not found for the supplied token.");

            return appUser;
        }

        private static List<Classroom> MergeDistinctClassrooms(
            List<Classroom> primary,
            List<Classroom> additional)
        {
            var byId = primary.ToDictionary(c => c.Id);
            foreach (var classroom in additional)
            {
                if (!byId.ContainsKey(classroom.Id))
                    byId[classroom.Id] = classroom;
            }

            return byId.Values
                .OrderBy(c => c.Name, StringComparer.OrdinalIgnoreCase)
                .ToList();
        }

        private static HashSet<int> BuildDesiredServantIds(
            IEnumerable<int>? servantIds,
            int? leaderServantId)
        {
            var desired = (servantIds ?? Array.Empty<int>())
                .Where(x => x > 0)
                .ToHashSet();

            if (leaderServantId is > 0)
                desired.Add(leaderServantId.Value);

            return desired;
        }

        private async Task ValidateServantIdsExistAsync(IEnumerable<int> ids)
        {
            var list = ids.Distinct().ToList();
            if (list.Count == 0)
                return;

            var servants = await _servantRepo.GetByIdsAsync(list);
            var foundIds = servants.Select(s => s.Id).ToHashSet();
            var missingServants = list.Where(id => !foundIds.Contains(id)).ToList();

            if (missingServants.Count == 0)
                return;

            throw new ValidationException(new Dictionary<string, string[]>
            {
                ["ServantIds"] = missingServants
                    .Select(id => $"Servant with id {id} was not found.")
                    .ToArray()
            });
        }

        private static void ApplyClassroomServantAssignments(
            Classroom classroom,
            HashSet<int> desired)
        {
            classroom.ClassroomServants ??= new List<ClassroomServant>();
            var existing = classroom.ClassroomServants.Select(cs => cs.ServantId).ToHashSet();

            var toRemove = classroom.ClassroomServants
                .Where(cs => !desired.Contains(cs.ServantId))
                .ToList();
            foreach (var cs in toRemove)
                classroom.ClassroomServants.Remove(cs);

            foreach (var servantId in desired)
            {
                if (existing.Contains(servantId))
                    continue;

                classroom.ClassroomServants.Add(new ClassroomServant
                {
                    ClassroomId = classroom.Id,
                    ServantId = servantId,
                    ChurchId = classroom.ChurchId,
                    MeetingId = classroom.MeetingId
                });
            }
        }
    }
}
