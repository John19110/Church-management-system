using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using System;
using System.Security.Claims;
using System.Threading.Tasks;

namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ClassroomController : ControllerBase
    {
        private readonly IClassroomManager _classroomManager;

        public ClassroomController(IClassroomManager classroomManager)
        {
            _classroomManager = classroomManager;
        }


        [HttpGet("visible")]
        public async Task<IActionResult> GetVisibleClassrooms()
        {
            var result = await _classroomManager.GetVisibleClassrooms();
            return Ok(result);
        }



    }
}