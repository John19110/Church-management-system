using Microsoft.AspNetCore.Mvc;
using SunDaySchools.API.Mapping;
using SunDaySchools.API.Requests;
using SunDaySchools.API.Services.Implementations;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Manager.Implementations;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.BLL.Exceptions;


namespace SunDaySchools.API.Controllers
{
    [ApiController]
    [Route("Api/[controller]")]
    public class AdminController : ControllerBase
    {

        private readonly IAdminManager _adminManager;
        private readonly IFileStorage _filestorage;

        public AdminController(IAdminManager adminmanager,IFileStorage filestorage)
        {
            _adminManager = adminmanager;
            _filestorage = filestorage;

        }

        [HttpPut("assign-class/{ServantId}/{ClassroomId}")]

        public ActionResult AssignClassToServant(int ServantId,int ClassroomId)
        {
            _adminManager.AssignClassToServant(ServantId, ClassroomId);
            return Ok();

        }

        [HttpPost("add-servant")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> AddServant(ServantAddDTO servant)
        {
            if (servant == null)
            {
                var errors = new Dictionary<string, string[]>
                {
                    ["childdto"] = new[] { "The request body cannot be empty." }
                };
                throw new ValidationException(errors);
            }
            _adminManager.AddServant(servant);

            return StatusCode(201, new { message = "Created Successfully" });
        }

      



    }

}