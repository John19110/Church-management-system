using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.DTOS;
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




        [HttpPost("add-meeting")]
        public async Task<IActionResult> AddMeeting(MeetingAddDTO meeting)
        {
            await _adminManager.AddMeeting(meeting);
            return Ok(new { message = "Meeting added successfully" });



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