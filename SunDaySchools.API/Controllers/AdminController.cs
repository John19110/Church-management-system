using Microsoft.AspNetCore.Mvc;
using SunDaySchools.API.Mapping;
using SunDaySchools.API.Requests;
using SunDaySchools.API.Services.Implementations;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.DTOS.Meeting;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;

namespace SunDaySchools.API.Controllers
{
    [ApiController]
    [Route("Api/[controller]")]
    public class AdminController : ControllerBase
    {
        private readonly IAdminManager _adminManager;
        private readonly IFileStorage _filestorage;
        private readonly IWebHostEnvironment _env;



        public AdminController(IAdminManager adminmanager, IFileStorage filestorage, IWebHostEnvironment env)
        {
            _adminManager = adminmanager;
            _filestorage = filestorage;
            _env = env;
        }


        // Get pending servants
        [HttpGet("pending-servants")]
        public async Task<ActionResult<List<PendingServantDTO>>> GetPendingServants()
        {
            var result = await _adminManager.GetPendingServants();
            return Ok(result);
        }

        [HttpPut("assign-class/{servantId}/{classroomId}")]
        public async Task<ActionResult> AssignClassToServant(int servantId, int classroomId)
        { 
            try
            {
                await _adminManager.AssignClassToServant(servantId, classroomId);
                return Ok(new { message = "Class assigned successfully" });
            }
            catch (NotFoundException ex)
            {
                return NotFound(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        // Approve servant
        [HttpPut("approve-servant/{userId}")]
        public async Task<IActionResult> ApproveServant(string userId)
        {
            await _adminManager.ApproveServant(userId);
            return Ok(new { message = "Servant approved successfully" });
        }

        // Reject servant
        [HttpDelete("reject-servant/{userId}")]
        public async Task<IActionResult> RejectServant(string userId)
        {
            await _adminManager.RejectServant(userId);
            return Ok(new { message = "Servant rejected successfully" });
        }




    }
}