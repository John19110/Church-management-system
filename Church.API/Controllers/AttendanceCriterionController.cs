using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Church.BLL.DTOS.AttendanceCriteria;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;

namespace Church.API.Controllers
{
    [Route("api")]
    [ApiController]
    [Authorize]
    public class AttendanceCriterionController : ControllerBase
    {
        private readonly IAttendanceCriterionManager _manager;

        public AttendanceCriterionController(IAttendanceCriterionManager manager)
        {
            _manager = manager;
        }

        /// <summary>Active criteria for take-attendance (Servant/Admin/SuperAdmin).</summary>
        [HttpGet("Meeting/{meetingId:int}/attendance-criteria")]
        [Authorize(Roles = "Servant,Admin,SuperAdmin")]
        public async Task<IActionResult> GetByMeeting(int meetingId, [FromQuery] bool includeInactive = false)
        {
            var result = await _manager.GetByMeetingAsync(meetingId, includeInactive);
            return Ok(result);
        }

        [HttpPost("Meeting/{meetingId:int}/attendance-criteria")]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> Add(int meetingId, [FromBody] AttendanceCriterionAddDTO dto)
        {
            if (dto == null)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["dto"] = new[] { "The request body cannot be empty." }
                });
            }

            var created = await _manager.AddAsync(meetingId, dto);
            return StatusCode(201, created);
        }

        [HttpPut("attendance-criteria/{id:int}")]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> Update(int id, [FromBody] AttendanceCriterionUpdateDTO dto)
        {
            if (dto == null)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["dto"] = new[] { "The request body cannot be empty." }
                });
            }

            var updated = await _manager.UpdateAsync(id, dto);
            return Ok(updated);
        }

        [HttpDelete("attendance-criteria/{id:int}")]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> SoftDelete(int id)
        {
            await _manager.SoftDeleteAsync(id);
            return Ok(new { message = "Criterion deleted." });
        }

        [HttpPut("Meeting/{meetingId:int}/attendance-criteria/reorder")]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> Reorder(int meetingId, [FromBody] AttendanceCriterionReorderDTO dto)
        {
            if (dto == null)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["dto"] = new[] { "The request body cannot be empty." }
                });
            }

            await _manager.ReorderAsync(meetingId, dto);
            return Ok(new { message = "Criteria reordered." });
        }
    }
}
