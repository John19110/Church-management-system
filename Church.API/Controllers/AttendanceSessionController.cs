using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Church.BLL.DTOS;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;


namespace Church.API.Controllers
{
    [Route("api/attendance-sessions")]
    [ApiController]
    [Authorize(Roles = "Servant,Admin,SuperAdmin")]
    public class AttendanceSessionController : ControllerBase
    {
        private readonly IAttendanceManager _attendanceManager;

        public AttendanceSessionController(IAttendanceManager attendanceManager)
        {
            _attendanceManager = attendanceManager ?? throw new ArgumentNullException(nameof(attendanceManager));
        }

        [HttpPost]
        public async Task<IActionResult> TakeAttendance([FromBody] AttendanceSessionAddDTO attendanceSession)
        {
            if (attendanceSession == null)
            {

                var errors = new Dictionary<string, string[]>
                {
                    ["attendanceSession"] = new[] { "The request body cannot be empty." }
                };
                throw new ValidationException(errors);
            }

            await _attendanceManager.TakeAttendanceAsync(attendanceSession);

            // Created without Location until TakeAttendance returns the new session id.
            return StatusCode(StatusCodes.Status201Created);
        }


        [HttpGet("{sessionId:int}")]
        public async Task<IActionResult> GetAttendance(int sessionId)
        {
            if (sessionId <= 0)
            {
                var errors = new Dictionary<string, string[]>
                {
                    ["sessionId"] = new[] { "The Session Id cant be less than 0." }
                };
                throw new ValidationException(errors);

            }
            var session = await _attendanceManager.GetAttendanceAsync(sessionId);

            if (session == null)
                throw new NotFoundException($"Sesstion with id {sessionId} not found.");

            return Ok(session);
        }

        /// <summary>
        /// List attendance history. Exactly one of classroomId or meetingId is required.
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetHistory(
            [FromQuery] int? classroomId,
            [FromQuery] int? meetingId)
        {
            if (classroomId is > 0 && meetingId is > 0)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    [""] = new[] { "Specify either classroomId or meetingId, not both." }
                });
            }

            if (classroomId is > 0)
            {
                var sessions = await _attendanceManager.GetHistoryByClassroomAsync(classroomId.Value);
                return Ok(sessions);
            }

            if (meetingId is > 0)
            {
                var sessions = await _attendanceManager.GetHistoryByMeetingAsync(meetingId.Value);
                return Ok(sessions);
            }

            throw new ValidationException(new Dictionary<string, string[]>
            {
                [""] = new[] { "Query parameter classroomId or meetingId is required." }
            });
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> UpdateAttendance(int id, [FromBody] AttendanceSessionUpdateDTO attendanceSession)
        {
            if (attendanceSession == null)
            {
                var errors = new Dictionary<string, string[]>
                {
                    ["attendanceSession"] = new[] { "The request body cannot be empty." }
                };
                throw new ValidationException(errors);
            }

            if (id != attendanceSession.Id)
            {
                var errors = new Dictionary<string, string[]>
                {
                    ["id"] = new[] { "The ID in the URL does not match the ID in the request body." }
                };
                throw new ValidationException(errors);
            }

            await _attendanceManager.EditAttendanceAsync(attendanceSession);

            return NoContent();
        }

       
    }
}
