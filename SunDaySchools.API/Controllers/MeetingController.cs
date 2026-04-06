using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.Manager.Interfaces;

namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class MeetingsController : ControllerBase
    {
        private readonly IMeetingManager _meetingManager;

        public MeetingsController(IMeetingManager meetingManager)
        {
            _meetingManager = meetingManager;
        }

        [HttpGet("select")]
        //[Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> GetMeetingsForSelection()
        {
            var result = await _meetingManager.GetMeetingsForSelection();
            return Ok(result);
        }

        [HttpGet("visible")]
        //[Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> GetvisibleMeetings()
        {
            var result = await _meetingManager.GetVisibleMeetings();
            return Ok(result);
        }





    }
}