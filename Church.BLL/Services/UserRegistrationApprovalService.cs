using Microsoft.AspNetCore.Identity;
using Church.BLL.DTOS.AccountDtos;
using Church.BLL.Exceptions;
using Church.DAL.Models;
using Church.DAL.Repository.Interfaces;
using Church.Domain;
using Church.DAL.Models;

namespace Church.BLL.Services
{
    /// <summary>
    /// Shared pending-user listing and approval logic for Church Super Admin and Meeting Admin.
    /// </summary>
    public sealed class UserRegistrationApprovalService
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IServantRepository _servantRepository;
        private readonly IMeetingRepository _meetingRepository;
        private readonly IChurchRepository _churchRepository;

        public UserRegistrationApprovalService(
            UserManager<ApplicationUser> userManager,
            IServantRepository servantRepository,
            IMeetingRepository meetingRepository,
            IChurchRepository churchRepository)
        {
            _userManager = userManager;
            _servantRepository = servantRepository;
            _meetingRepository = meetingRepository;
            _churchRepository = churchRepository;
        }

        public async Task<List<PendingUserDTO>> MapPendingUsersAsync(
            IReadOnlyList<ApplicationUser> users,
            int churchId)
        {
            var church = await _churchRepository.GetByIdAsync(churchId);
            var churchPublicId = church?.PublicId;

            var meetingPublicIds = new Dictionary<int, string>();
            var requestedMeetingIds = users
                .Where(u => u.RequestedMeetingId.HasValue)
                .Select(u => u.RequestedMeetingId!.Value)
                .Distinct()
                .ToList();

            foreach (var meetingId in requestedMeetingIds)
            {
                var meeting = await _meetingRepository.GetByIdAsync(meetingId);
                if (meeting != null)
                    meetingPublicIds[meetingId] = meeting.PublicId;
            }

            var result = new List<PendingUserDTO>();

            foreach (var user in users)
            {
                var roles = await _userManager.GetRolesAsync(user);
                var role = roles.FirstOrDefault() ?? user.RequestedRole ?? string.Empty;

                var servant = string.IsNullOrEmpty(user.ImageUrl) && string.IsNullOrEmpty(user.ImageFileName)
                    ? await _servantRepository.GetByApplicationUserIdAsync(user.Id)
                    : null;

                string? requestedMeetingPublicId = null;
                if (user.RequestedMeetingId.HasValue
                    && meetingPublicIds.TryGetValue(user.RequestedMeetingId.Value, out var mpid))
                {
                    requestedMeetingPublicId = mpid;
                }

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
                    RequestedMeetingId = user.RequestedMeetingId,
                    RequestedMeetingPublicId = requestedMeetingPublicId,
                    RegisteredViaMeetingId = user.RequestedMeetingId.HasValue,
                    ImageUrl = user.ImageUrl ?? servant?.ImageUrl,
                    ImageFileName = user.ImageFileName ?? servant?.ImageFileName,
                    CreatedAt = user.CreatedAt
                });
            }

            return result;
        }

        public async Task ApproveUserAsync(
            ApplicationUser user,
            int churchId,
            string approverUserId,
            int? meetingIdFromRequest,
            int? approverMeetingId)
        {
            EnsureSameChurch(user, churchId);

            if (approverMeetingId.HasValue)
            {
                if (user.RequestedMeetingId != approverMeetingId)
                {
                    throw new UnauthorizedAccessException(
                        "You can only approve users who registered with your meeting ID.");
                }
            }

            if (user.RegistrationStatus == RegistrationStatus.Approved)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["User"] = new[] { "User is already approved." }
                });
            }

            if (user.RegistrationStatus == RegistrationStatus.Rejected)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["User"] = new[] { "Rejected users cannot be approved." }
                });
            }

            var roles = await _userManager.GetRolesAsync(user);

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
                assignedMeetingId = meetingIdFromRequest ?? user.RequestedMeetingId;

                if (assignedMeetingId is null)
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["MeetingId"] = new[] { "A meeting must be selected for this role." }
                    });
                }

                var meeting = await _meetingRepository.GetByIdAsync(assignedMeetingId.Value)
                    ?? throw new NotFoundException($"Meeting with id {assignedMeetingId} not found.");

                if (meeting.ChurchId != churchId)
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["MeetingId"] = new[] { "The selected meeting does not belong to your church." }
                    });
                }

                if (user.RequestedMeetingId.HasValue && user.RequestedMeetingId != assignedMeetingId)
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["MeetingId"] = new[] { "The user must be assigned to the meeting they registered with." }
                    });
                }
            }

            var identityRole = MapRequestedRoleToIdentityRole(user.RequestedRole);
            if (!await _userManager.IsInRoleAsync(user, identityRole))
                await _userManager.AddToRoleAsync(user, identityRole);

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
            user.ApprovedByUserId = approverUserId;
            user.ApprovalDate = DateTime.Now;
            user.RejectionReason = null;

            await UpdateUserOrThrow(user);
        }

        public async Task RejectUserAsync(
            ApplicationUser user,
            int churchId,
            string approverUserId,
            string? reason,
            int? approverMeetingId)
        {
            EnsureSameChurch(user, churchId);

            if (approverMeetingId.HasValue && user.RequestedMeetingId != approverMeetingId)
            {
                throw new UnauthorizedAccessException(
                    "You can only reject users who registered with your meeting ID.");
            }

            if (user.RegistrationStatus == RegistrationStatus.Approved)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["User"] = new[] { "Approved users cannot be rejected." }
                });
            }

            user.RegistrationStatus = RegistrationStatus.Rejected;
            user.IsApproved = false;
            user.RejectionReason = string.IsNullOrWhiteSpace(reason) ? null : reason.Trim();
            user.ApprovedByUserId = approverUserId;
            user.ApprovalDate = DateTime.Now;

            await UpdateUserOrThrow(user);
        }

        private static void EnsureSameChurch(ApplicationUser user, int churchId)
        {
            var userChurch = user.RequestedChurchId ?? user.ChurchId;
            if (userChurch != churchId)
            {
                throw new UnauthorizedAccessException(
                    "You can only manage users requesting access to your own church.");
            }
        }

        private static string MapRequestedRoleToIdentityRole(string? requestedRole)
        {
            var value = (requestedRole ?? string.Empty).Trim().Replace(" ", "");
            if (string.Equals(value, "MeetingAdmin", StringComparison.OrdinalIgnoreCase))
                return "Admin";
            if (string.Equals(value, "ChurchAdmin", StringComparison.OrdinalIgnoreCase))
                return "SuperAdmin";
            return "Servant";
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
                        g => g.Select(e => e.Description).ToArray());

                throw new ValidationException(errors);
            }
        }
    }

}
