using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Models;
namespace SunDaySchools.API.Controllers
{
        [Route("Api/[controller]")]
        [ApiController]
    public class AttendanceSessionController:ControllerBase
    {
        private readonly IAttendanceManager _attendanceManager;
        public AttendanceSessionController(IAttendanceManager attendanceManager)
        {
            _attendanceManager = attendanceManager;
        }

        [HttpPost]
        public Task<IActionResult> TakeAttendance([FromBody] AttendanceSession attendanceSession)
        {
            if (attendanceSession == null) return Task.FromResult<IActionResult>(BadRequest("AttendanceSession is required."));
            var created = _attendanceManager.TakeAttendance(attendanceSession);
            // return 201 with location header to GET endpoint
            return Task.FromResult<IActionResult>(CreatedAtAction(nameof(GetAttendance), new { SessionId = created.Id }, created));
        }

        [HttpPut("{id}")]
        public Task<IActionResult> UpdateAttendance(int id, [FromBody] AttendanceSession attendanceSession)
        {
            if (attendanceSession == null) return Task.FromResult<IActionResult>(BadRequest("AttendanceSession is required."));
            if (id != attendanceSession.Id) return Task.FromResult<IActionResult>(BadRequest("Route id and body id do not match."));

            var updated = _attendanceManager.EditAttendance(attendanceSession);
            return Task.FromResult<IActionResult>(Ok(updated));
        }

        [HttpGet("{SessionId}")]
        public Task<IActionResult> GetAttendance(int SessionId)
        {
            if (SessionId <= 0) return Task.FromResult<IActionResult>(BadRequest("Invalid SessionId."));

            var session = _attendanceManager.GetAttendance(SessionId);
            if (session == null) return Task.FromResult<IActionResult>(NotFound());

            return Task.FromResult<IActionResult>(Ok(session));
        }


        public void Delete(int id)
        {

            _sarventReposatory.Delete(id);
        }
    }


}

