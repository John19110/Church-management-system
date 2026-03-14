using Microsoft.AspNetCore.Mvc;
using SunDaySchools.API.Requests;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Manager.Implementations;
using SunDaySchools.BLL.Manager.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.API.Mapping;
using SunDaySchools.API.Requests;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using System.Security.Claims;
namespace SunDaySchools.API.Controllers
{
    [ApiController]
    [Route("Api/[controller]")]
    public class AdminController : ControllerBase
    {

        private readonly IAdminManager _adminManager;
        public AdminController(IAdminManager adminmanager)
        {
            _adminManager = adminmanager;

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
                var key = await _fileStorage.SaveImageAsync(form.Image, ct, "servants");
                dto.ImageFileName = key;
                dto.ImageUrl = _fileStorage.GetPublicUrl(key);
            }

            _servantManager.Add(dto);

            return Ok();
        }




    }

}