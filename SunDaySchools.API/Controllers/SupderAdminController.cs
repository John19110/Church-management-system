using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;

namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "SuperAdmin")]
    public class SuperAdminController : ControllerBase
    {
        private readonly ISuperAdminManager _superAdminManager;

        public SuperAdminController(ISuperAdminManager superAdminManager)
        {
            _superAdminManager = superAdminManager;
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
    }
}