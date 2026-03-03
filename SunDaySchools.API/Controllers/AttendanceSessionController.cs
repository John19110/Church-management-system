using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.DTOS;
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
                return BadRequest("AttendanceSession is required.");

            await _attendanceManager.TakeAttendanceAsync(attendanceSession);

            // If you have a GET by id endpoint and your repo returns the created id,
            // prefer CreatedAtAction. For now, OK is fine.
            return Ok();
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> UpdateAttendance(int id, [FromBody] AttendanceSessionUpdateDTO attendanceSession)
        {
            if (attendanceSession == null)
                return BadRequest("AttendanceSession is required.");

            if (id != attendanceSession.Id)
                return BadRequest("Route id and body id do not match.");

            await _attendanceManager.EditAttendanceAsync(attendanceSession);

            return Ok();
        }

        [HttpGet("{sessionId:int}")]
        public async Task<IActionResult> GetAttendance(int sessionId)
        {
            if (sessionId <= 0)
                return BadRequest("Invalid sessionId.");

            var session = await _attendanceManager.GetAttendanceAsync(sessionId);

            if (session == null)
                return NotFound();

            return Ok(session);
        }
    }
}