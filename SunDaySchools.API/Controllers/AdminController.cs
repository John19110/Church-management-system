using Microsoft.AspNetCore.Mvc;
using SunDaySchools.API.Mapping;
using SunDaySchools.API.Requests;
using SunDaySchools.API.Services.Implementations;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.AccountDtos;
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

        public AdminController(IAdminManager adminmanager, IFileStorage filestorage)
        {
            _adminManager = adminmanager;
            _filestorage = filestorage;
        }

        // Assign classroom to servant
        [HttpPut("assign-class/{ServantId}/{ClassroomId}")]
        public ActionResult AssignClassToServant(int ServantId, int ClassroomId)
        {
            _adminManager.AssignClassToServant(ServantId, ClassroomId);
            return Ok(new { message = "Class assigned successfully" });
        }

        // Add servant
        [HttpPost("add-servant")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> AddServant([FromForm(Name = "")] AdminAddServantDTO servant)
        {
            if (servant == null)
            {
                var errors = new Dictionary<string, string[]>
                {
                    ["servant"] = new[] { "The request body cannot be empty." }
                };
                throw new ValidationException(errors);
            }

           await _adminManager.AddServant(servant);

            return  StatusCode(201, new { message = "Created Successfully" });
        }

        // =========================
        // NEW ENDPOINTS
        // =========================

        // Get pending servants
        [HttpGet("pending-servants")]
        public async Task<ActionResult<List<PendingServantDTO>>> GetPendingServants()
        {
            var result = await _adminManager.GetPendingServants();
            return Ok(result);
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