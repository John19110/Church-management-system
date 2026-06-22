using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.BLL.Abstractions;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.BLL.Services;
using SunDaySchools.DAL.Abstractions;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;

namespace SunDaySchools.BLL.Manager.Implementations
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
                        g => g.Select(e => e.Description).ToArray());

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
