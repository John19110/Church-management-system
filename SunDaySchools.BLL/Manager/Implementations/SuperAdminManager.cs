using AutoMapper;
using Microsoft.AspNetCore.Identity;
using SunDaySchools.BLL.Abstractions;
using SunDaySchools.DAL.Abstractions;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Repository.Implementations;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using SunDaySchools.BLL.DTOS.Meeting;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class SuperAdminManager: ISuperAdminManager
    {

        private readonly ITenantContext _tenantContext;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IServantRepository _servantRepository;
        private readonly IMeetingRepository _meetingRepository;
        private readonly IChurchRepository _churchRepository;
        private readonly ICurrentUserContext _currentUser;


        public SuperAdminManager(
            ITenantContext tenantContext,
            UserManager<ApplicationUser> usermanager,
            IServantRepository servantRepository,
            IMeetingRepository meetingRepository,
            IChurchRepository churchRepository,
            ICurrentUserContext currentUser)
        {
            _tenantContext = tenantContext;
            _userManager = usermanager;
            _servantRepository = servantRepository;
            _meetingRepository = meetingRepository;
            _churchRepository = churchRepository;
            _currentUser = currentUser;
        }


        public async Task<List<PendingServantDTO>> GetPendingAdmins()
        {
            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing");

            var users = await _userManager.Users
                                        .Where(u => !u.IsApproved && u.ChurchId == churchId)
                                        .ToListAsync();

            var result = new List<PendingServantDTO>();

            foreach (var user in users)
            {
                if (await _userManager.IsInRoleAsync(user, "Admin"))
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


        public async Task RejectAdmin(string userId)
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


        public async Task ApproveAdmin(string userId)
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

        // ---- Church user approval workflow ----

        public async Task<List<PendingUserDTO>> GetPendingUsers()
        {
            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing");

            var church = await _churchRepository.GetByIdAsync(churchId);
            var churchPublicId = church?.PublicId;

            var users = await _userManager.Users
                .Where(u => u.RegistrationStatus == RegistrationStatus.Pending
                            && (u.RequestedChurchId == churchId || u.ChurchId == churchId))
                .ToListAsync();

            var result = new List<PendingUserDTO>();

            foreach (var user in users)
            {
                var roles = await _userManager.GetRolesAsync(user);
                var role = roles.FirstOrDefault() ?? user.RequestedRole ?? string.Empty;

                // Pending users carry their photo on the account; fall back to a servant row if one exists.
                var servant = string.IsNullOrEmpty(user.ImageUrl) && string.IsNullOrEmpty(user.ImageFileName)
                    ? await _servantRepository.GetByApplicationUserIdAsync(user.Id)
                    : null;

                result.Add(new PendingUserDTO
                {
                    Id = user.Id,
                    Name = user.UserName ?? string.Empty,
                    PhoneNumber = user.PhoneNumber ?? string.Empty,
                    Role = role,
                    RequestedRole = user.RequestedRole,
                    RequestedMeetingName = user.RequestedMeetingName,
                    MeetingAdminPhoneNumber = user.MeetingAdminPhoneNumber,
                    RequestedChurchId = user.RequestedChurchId ?? user.ChurchId,
                    RequestedChurchPublicId = churchPublicId,
                    ImageUrl = user.ImageUrl ?? servant?.ImageUrl,
                    ImageFileName = user.ImageFileName ?? servant?.ImageFileName,
                    CreatedAt = user.CreatedAt
                });
            }

            return result;
        }

        public async Task ApproveUser(string userId, int? meetingId)
        {
            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing");

            var user = await _userManager.FindByIdAsync(userId)
                ?? throw new NotFoundException($"User with id {userId} not found.");

            EnsureSameChurch(user, churchId);

            if (user.RegistrationStatus == RegistrationStatus.Approved)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["User"] = new[] { "User is already approved." }
                });

            var roles = await _userManager.GetRolesAsync(user);

            // Servant / Meeting Admin must be assigned to a meeting; Church Admin (SuperAdmin) need not.
            var requiresMeeting = user.RequestedRole switch
            {
                "Servant" => true,
                "MeetingAdmin" => true,
                "ChurchAdmin" => false,
                _ => roles.Contains("Servant") || roles.Contains("Admin")
            };

            int? assignedMeetingId = null;

            if (requiresMeeting)
            {
                if (meetingId is null)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["MeetingId"] = new[] { "A meeting must be selected for this role." }
                    });

                var meeting = await _meetingRepository.GetByIdAsync(meetingId.Value)
                    ?? throw new NotFoundException($"Meeting with id {meetingId} not found.");

                if (meeting.ChurchId != churchId)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["MeetingId"] = new[] { "The selected meeting does not belong to your church." }
                    });

                assignedMeetingId = meetingId;
            }

            // Activate the requested role (pending users have no role assigned yet).
            var identityRole = MapRequestedRoleToIdentityRole(user.RequestedRole);
            if (!await _userManager.IsInRoleAsync(user, identityRole))
                await _userManager.AddToRoleAsync(user, identityRole);

            // Create or update the Servant profile from the data captured at registration.
            var servant = await _servantRepository.GetTrackedProfileByApplicationUserIdAsync(user.Id);
            if (servant == null)
            {
                servant = new Servant
                {
                    ApplicationUserId = user.Id,
                    Name = user.UserName ?? string.Empty,
                    PhoneNumber = user.PhoneNumber ?? string.Empty,
                    BirthDate = user.BirthDate,
                    JoiningDate = user.JoiningDate ?? user.BirthDate,
                    ChurchId = churchId,
                    MeetingId = assignedMeetingId,
                    ImageFileName = user.ImageFileName,
                    ImageUrl = user.ImageUrl
                };
                await _servantRepository.AddAsync(servant);
            }
            else
            {
                servant.ChurchId = churchId;
                servant.MeetingId = assignedMeetingId;
                await _servantRepository.SaveChangesAsync();
            }

            user.ChurchId = churchId;
            user.MeetingId = assignedMeetingId;
            user.RegistrationStatus = RegistrationStatus.Approved;
            user.IsApproved = true;
            user.ApprovedByUserId = _currentUser.UserId;
            user.ApprovalDate = DateTime.Now;
            user.RejectionReason = null;

            await UpdateUserOrThrow(user);
        }

        /// <summary>Maps a requested role to an ASP.NET Identity role (only Admin/Servant/SuperAdmin exist).</summary>
        private static string MapRequestedRoleToIdentityRole(string? requestedRole)
        {
            var value = (requestedRole ?? string.Empty).Trim().Replace(" ", "");
            if (string.Equals(value, "MeetingAdmin", StringComparison.OrdinalIgnoreCase))
                return "Admin";
            if (string.Equals(value, "ChurchAdmin", StringComparison.OrdinalIgnoreCase))
                return "SuperAdmin";
            return "Servant";
        }

        public async Task RejectUser(string userId, string? reason)
        {
            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing");

            var user = await _userManager.FindByIdAsync(userId)
                ?? throw new NotFoundException($"User with id {userId} not found.");

            EnsureSameChurch(user, churchId);

            if (user.RegistrationStatus == RegistrationStatus.Approved)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["User"] = new[] { "Approved users cannot be rejected." }
                });

            user.RegistrationStatus = RegistrationStatus.Rejected;
            user.IsApproved = false;
            user.RejectionReason = string.IsNullOrWhiteSpace(reason) ? null : reason.Trim();
            user.ApprovedByUserId = _currentUser.UserId;
            user.ApprovalDate = DateTime.Now;

            await UpdateUserOrThrow(user);
        }

        private static void EnsureSameChurch(ApplicationUser user, int churchId)
        {
            var userChurch = user.RequestedChurchId ?? user.ChurchId;
            if (userChurch != churchId)
                throw new UnauthorizedAccessException(
                    "You can only manage users requesting access to your own church.");
        }

        private async Task UpdateUserOrThrow(ApplicationUser user)
        {
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

    }
}
