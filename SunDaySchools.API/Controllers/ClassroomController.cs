using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.ClsssroomDtos;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Implementations;
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
        private readonly IServantManager _servantManager;
        private readonly IMemberManager _memberManager;



        public ClassroomController(IClassroomManager classroomManager, IServantManager servantManager,
                                    IMemberManager memberManager)
        {
            _classroomManager = classroomManager;
            _servantManager = servantManager;
            _memberManager = memberManager;

        }


        [HttpPost]
        public async Task<IActionResult> Create(ClassroomAddDTO classroom)
        {
            await _classroomManager.AddAsync(classroom);
            return Ok();
        }

        [HttpGet("visible")]
        public async Task<IActionResult> GetVisibleClassrooms([FromQuery] int? meetingId = null)
        {
            var result = await _classroomManager.GetVisibleClassrooms(meetingId);
            return Ok(result);
        }


        [HttpGet("select")]
        //[Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> GetClassroomsForSelection()
        {
            var result = await _classroomManager.GetClassroomsForSelection();
            return Ok(result);
        }





    }
}