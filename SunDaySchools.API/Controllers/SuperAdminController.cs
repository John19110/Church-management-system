using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.DTOS.Meeting;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Implementations;
using SunDaySchools.BLL.Manager.Interfaces;

namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "SuperAdmin")]
    public class SuperAdminController : ControllerBase
    {
        private readonly ISuperAdminManager _superAdminManager;
        private readonly IAdminManager _adminManager;




        public SuperAdminController(ISuperAdminManager superAdminManager, IAdminManager adminManager)
        {
            _superAdminManager = superAdminManager;
            _adminManager = adminManager;
        }


        [HttpGet("pending-admins")]
        public async Task<ActionResult<List<PendingServantDTO>>> GetPendingAdmins()
        {
            var pendingAdmins = await _superAdminManager.GetPendingAdmins();
            return Ok(pendingAdmins);
        }

        [HttpPut("approve-admin/{userId}")]
        public async Task<IActionResult> ApproveAdmin(string userId)
        {
            await _superAdminManager.ApproveAdmin(userId);
            return Ok(new { message = "Admin approved successfully." });
        }

        [HttpDelete("reject-admin/{userId}")]
        public async Task<IActionResult> RejectAdmin(string userId)
        {
            await _superAdminManager.RejectAdmin(userId);
            return Ok(new { message = "Admin rejected successfully." });
        }

        // ---- Church user approval workflow (Super Admin controlled) ----

        /// <summary>Pending users (any role) requesting access to the Super Admin's church.</summary>
        [HttpGet("pending-users")]
        public async Task<ActionResult<List<PendingUserDTO>>> GetPendingUsers()
        {
            var pending = await _superAdminManager.GetPendingUsers();
            return Ok(pending);
        }

        /// <summary>Approve a pending user, assigning a meeting when the role requires it.</summary>
        [HttpPost("approve-user/{userId}")]
        public async Task<IActionResult> ApproveUser(string userId, [FromBody] ApproveUserDTO? dto)
        {
            await _superAdminManager.ApproveUser(userId, dto?.MeetingId);
            return Ok(new { message = "User approved successfully." });
        }

        /// <summary>Reject a pending user with an optional reason; the user remains unable to login.</summary>
        [HttpPost("reject-user/{userId}")]
        public async Task<IActionResult> RejectUser(string userId, [FromBody] RejectUserDTO? dto)
        {
            await _superAdminManager.RejectUser(userId, dto?.Reason);
            return Ok(new { message = "User rejected successfully." });
        }


    }
}