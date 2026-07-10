using AutoMapper;
using Microsoft.AspNetCore.Identity;
using Church.BLL.Abstractions;
using Church.DAL.Abstractions;
using Microsoft.EntityFrameworkCore;
using Church.BLL.DTOS.AccountDtos;
using Church.BLL.DTOS.Meeting;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;
using Church.BLL.Services;
using Church.DAL.Models;
using Church.DAL.Repository.Implementations;
using Church.DAL.Repository.Interfaces;
using Church.Domain;
using Church.DAL.Models;



namespace Church.BLL.Manager.Implementations
{
    public class AdminManager : IAdminManager
    {

        
    private readonly IAdminRepository _adminRepository;
    private readonly IMapper _mapper;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ITenantContext _tenantContext;
    private readonly IAccountManager _accountManager;
    private readonly IMeetingRepository _meetingRepository;
    private readonly ICurrentUserContext _currentUser;
    private readonly UserRegistrationApprovalService _approvalService;

        public AdminManager(IAdminRepository adminRepository,IMapper mapper
            , UserManager<ApplicationUser> usermanager, ITenantContext tenantContext
            ,IAccountManager accountManager,IMeetingRepository meetingRepository
            , ICurrentUserContext currentUser
            , UserRegistrationApprovalService approvalService)
        {
            _adminRepository = adminRepository;
            _mapper = mapper;
            _userManager = usermanager;
            _tenantContext = tenantContext;
            _accountManager = accountManager;
            _meetingRepository = meetingRepository;
            _currentUser = currentUser;
            _approvalService = approvalService;
        }

        public async Task AssignClassToServant(int servantId, int classroomId)
        {
            var (servant, classroom) = await _adminRepository.GetServantAndClassroomAsync(servantId, classroomId);

            if (servant is null)
                throw new NotFoundException($"Servant with id {servantId} not found");

            if (classroom is null)
                throw new NotFoundException($"Classroom with id {classroomId} not found");

            var exists = await _adminRepository.ClassroomServantExistsAsync(servantId, classroomId);

            if (exists)
                throw new Exception("Servant is already assigned to this class");

            var relation = new ClassroomServant
            {
                ServantId = servantId,
                ClassroomId = classroomId,
                ChurchId = classroom.ChurchId,
                MeetingId = classroom.MeetingId
            };

            await _adminRepository.AddClassroomServantAsync(relation);

            await _adminRepository.SaveAsync();
        }

        // In Service (BLL)
        //public async Task AddServant(AdminAddServantDTO servantDto, string webRootPath)
        //{
        //    var registerDTO = _mapper.Map<RegisterServantDTO>(servantDto.Account);
        //    registerDTO.Image = servantDto.Servant.Image;

        //    // ChurchId logic
        //    var claim = _httpContextAccessor.HttpContext?.User?.FindFirst("ChurchId");
        //    if (claim == null) throw new UnauthorizedAccessException("ChurchId claim is missing");
        //    if (!int.TryParse(claim.Value, out var churchId)) throw new UnauthorizedAccessException("Invalid ChurchId");
        //    registerDTO.ChurchId = churchId;

        //    // ✅ Pass webRootPath here
        //    var createdUserToken = await _accountManager.RegisterServant(registerDTO, webRootPath);

        //    var handler = new JwtSecurityTokenHandler();
        //    var jwtToken = handler.ReadJwtToken(createdUserToken);

        //    // Raw JWT carries user id as "sub"
        //    var userId = jwtToken.Claims.FirstOrDefault(c => c.Type == JwtRegisteredClaimNames.Sub)?.Value;
        //    var user = await _userManager.FindByIdAsync(userId);

        //    user.IsApproved = true;
        //    await _userManager.UpdateAsync(user);

        //    // Optional: assign classrooms
        //}
        public async Task<List<PendingServantDTO>> GetPendingServants()
        {
            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing");

            var users = await _userManager.Users
                                        .Where(u => !u.IsApproved && u.ChurchId == churchId)
                                        .ToListAsync();

            var result = new List<PendingServantDTO>();

            foreach (var user in users)
            {
                if (await _userManager.IsInRoleAsync(user, "Servant"))
                {
                    result.Add(new PendingServantDTO
                    {
                        Id = user.Id,
                        Name = user.UserName,
                        PhoneNumber = user.PhoneNumber
                    });
                }
            }

            return result;
        }
        public async Task ApproveServant(string userId)
        {
            var user = await _userManager.FindByIdAsync(userId);

            if (user == null)
                throw new NotFoundException($"User with id {userId} not found.");

            if (user.IsApproved)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["User"] = new[] { "User is already approved." }
                });

            user.IsApproved = true;

            var result = await _userManager.UpdateAsync(user);

            if (!result.Succeeded)
            {
                var errors = result.Errors
                    .GroupBy(e => e.Code)
                    .ToDictionary(
                        g => g.Key,
                        g => g.Select(e => e.Description).ToArray()
                    );

                throw new ValidationException(errors);
            }
        }

        public async Task RejectServant(string userId)
        {
            var user = await _userManager.FindByIdAsync(userId);

            if (user == null)
                throw new NotFoundException($"User with id {userId} not found.");

            if (user.IsApproved)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["User"] = new[] { "Approved users cannot be rejected." }
                });

            var result = await _userManager.DeleteAsync(user);

            if (!result.Succeeded)
            {
                var errors = result.Errors
                    .GroupBy(e => e.Code)
                    .ToDictionary(
                        g => g.Key,
                        g => g.Select(e => e.Description).ToArray()
                    );

                throw new ValidationException(errors);
            }
        }

        public async Task<List<PendingUserDTO>> GetPendingUsers()
        {
            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing");

            var approver = await RequireCurrentAdminUserAsync();
            var meetingId = approver.MeetingId
                ?? throw new UnauthorizedAccessException("Meeting Admin must be assigned to a meeting.");

            var users = await _userManager.Users
                .Where(u => u.RegistrationStatus == RegistrationStatus.Pending
                            && u.RequestedMeetingId == meetingId
                            && (u.RequestedChurchId == churchId || u.ChurchId == churchId))
                .ToListAsync();

            return await _approvalService.MapPendingUsersAsync(users, churchId);
        }

        public async Task ApproveUser(string userId, int? meetingId)
        {
            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing");

            var approver = await RequireCurrentAdminUserAsync();
            var approverMeetingId = approver.MeetingId
                ?? throw new UnauthorizedAccessException("Meeting Admin must be assigned to a meeting.");

            var user = await _userManager.FindByIdAsync(userId)
                ?? throw new NotFoundException($"User with id {userId} not found.");

            await _approvalService.ApproveUserAsync(
                user,
                churchId,
                _currentUser.UserId ?? string.Empty,
                meetingId,
                approverMeetingId);
        }

        public async Task RejectUser(string userId, string? reason)
        {
            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing");

            var approver = await RequireCurrentAdminUserAsync();
            var approverMeetingId = approver.MeetingId
                ?? throw new UnauthorizedAccessException("Meeting Admin must be assigned to a meeting.");

            var user = await _userManager.FindByIdAsync(userId)
                ?? throw new NotFoundException($"User with id {userId} not found.");

            await _approvalService.RejectUserAsync(
                user,
                churchId,
                _currentUser.UserId ?? string.Empty,
                reason,
                approverMeetingId);
        }

        private async Task<ApplicationUser> RequireCurrentAdminUserAsync()
        {
            if (!_currentUser.IsAuthenticated || string.IsNullOrWhiteSpace(_currentUser.UserId))
                throw new UnauthorizedAccessException("User is not authenticated.");

            var appUser = await _userManager.FindByIdAsync(_currentUser.UserId);
            if (appUser == null)
                throw new UnauthorizedAccessException("User account not found.");

            return appUser;
        }
    }
}
