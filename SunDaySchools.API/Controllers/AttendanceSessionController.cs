using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using System;
using System.Threading.Tasks;

namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
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

            // If you have a GET by id endpoint and your repo returns the created id,
            // prefer CreatedAtAction. For now, OK is fine.
            return Ok();
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

            return Ok();
        }

       
    }
}