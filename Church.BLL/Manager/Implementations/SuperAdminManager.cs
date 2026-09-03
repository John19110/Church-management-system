using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Church.BLL.Abstractions;
using Church.BLL.DTOS.AccountDtos;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;
using Church.BLL.Services;
using Church.DAL.Abstractions;
using Church.Domain;
using Church.DAL.Models;

namespace Church.BLL.Manager.Implementations
{
    public class SuperAdminManager : ISuperAdminManager
    {
        private readonly ITenantContext _tenantContext;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ICurrentUserContext _currentUser;
        private readonly UserRegistrationApprovalService _approvalService;

        public SuperAdminManager(
            ITenantContext tenantContext,
            UserManager<ApplicationUser> usermanager,
            ICurrentUserContext currentUser,
            UserRegistrationApprovalService approvalService)
        {
            _tenantContext = tenantContext;
            _userManager = usermanager;
            _currentUser = currentUser;
            _approvalService = approvalService;
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

        /// <summary>
        /// ApplicationUser has no global tenant query filter, so <see cref="UserManager{T}.FindByIdAsync"/>
        /// resolves accounts in every church. Approval and rejection must therefore scope the lookup
        /// to the caller's church explicitly, or a Super Admin can approve or delete accounts in
        /// another tenant just by supplying that user's id.
        /// </summary>
        private async Task<ApplicationUser> FindUserInCallerChurchAsync(string userId)
        {
            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing");

            var user = await _userManager.FindByIdAsync(userId);

            // Pending self-registrations carry RequestedChurchId until approval assigns ChurchId.
            if (user == null || (user.ChurchId != churchId && user.RequestedChurchId != churchId))
                throw new NotFoundException($"User with id {userId} not found.");

            return user;
        }

        public async Task RejectAdmin(string userId)
        {
            var user = await FindUserInCallerChurchAsync(userId);

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
                        g => g.Select(e => e.Description).ToArray());

                throw new ValidationException(errors);
            }
        }

        public async Task ApproveAdmin(string userId)
        {
            var user = await FindUserInCallerChurchAsync(userId);

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
                        g => g.Select(e => e.Description).ToArray());

                throw new ValidationException(errors);
            }
        }

        public async Task<List<PendingUserDTO>> GetPendingUsers()
        {
            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing");

            var users = await _userManager.Users
                .Where(u => u.RegistrationStatus == RegistrationStatus.Pending
                            && (u.RequestedChurchId == churchId || u.ChurchId == churchId))
                .ToListAsync();

            return await _approvalService.MapPendingUsersAsync(users, churchId);
        }

        public async Task ApproveUser(string userId, int? meetingId)
        {
            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing");

            var user = await _userManager.FindByIdAsync(userId)
                ?? throw new NotFoundException($"User with id {userId} not found.");

            await _approvalService.ApproveUserAsync(
                user,
                churchId,
                _currentUser.UserId ?? string.Empty,
                meetingId,
                approverMeetingId: null);
        }

        public async Task RejectUser(string userId, string? reason)
        {
            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing");

            var user = await _userManager.FindByIdAsync(userId)
                ?? throw new NotFoundException($"User with id {userId} not found.");

            await _approvalService.RejectUserAsync(
                user,
                churchId,
                _currentUser.UserId ?? string.Empty,
                reason,
                approverMeetingId: null);
        }
    }
}
