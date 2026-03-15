using Microsoft.AspNetCore.Mvc;
using SunDaySchools.API.Requests;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Manager.Implementations;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.API.Mapping;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.API.Services.Implementations;


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

        [HttpPost("add-servant{}")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> AddServant([FromForm] ServantFormRequest form, CancellationToken ct)
        {
            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);

            var dto = form.ToAddDto();

            if (form.Image is not null && form.Image.Length > 0)
            {
                var key = await _filestorage.SaveImageAsync(form.Image, ct, "servants");
                dto.ImageFileName = key;
                dto.ImageUrl = _filestorage.GetPublicUrl(key);
            }

            AdminManager.AddServant(dto);

            return Ok();
        }




    }

}