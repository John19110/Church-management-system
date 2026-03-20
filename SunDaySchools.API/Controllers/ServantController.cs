using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.API.Mapping;
using SunDaySchools.API.Requests;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using System.Security.Claims;

namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ServantController : ControllerBase
    {
        private readonly IServantManager _servantManager;
        private readonly IFileStorage _fileStorage;

        public ServantController(IServantManager servantManager, IFileStorage fileStorage)
        {
            _servantManager = servantManager;
            _fileStorage = fileStorage;
        }

        [HttpGet]
        public ActionResult GetAll()
        {
            var servants = _servantManager.GetAll();
            return Ok(servants);
        }

        [HttpGet("{id:int}")]
        public ActionResult GetById(int id)
        {
            var servant = _servantManager.GetById(id);

            if (servant == null)
                throw new NotFoundException($"Servant with id {id} not found.");

            return Ok(servant);
        }
       
        //[Authorize]
        //[HttpGet("my-classes")]
        //public async Task<IActionResult> GetMyClasses()
        //{
        //    try
        //    {
        //        // 1. Extract user ID from token
        //        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        //        if (string.IsNullOrEmpty(userId))
        //            return Unauthorized("Invalid token");

        //        // 2. Call business layer
        //        var classes = await _servantManager.GetClassesByUserId(userId);

        //        return Ok(classes);
        //    }
        //    catch (Exception)
        //    {
        //        return StatusCode(500, "Server error");
        //    }
        //}
        [HttpPut("{id:int}")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Update(int id, [FromForm] ServantFormRequest form, CancellationToken ct)
        {
            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);

            var updateDto = form.ToUpdateDto();

            updateDto.Id = id;

            updateDto.ApplicationUserId= User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (form.Image is not null && form.Image.Length > 0)
            {
                var key = await _fileStorage.SaveImageAsync(form.Image, ct, "servants");
                updateDto.ImageFileName = key;
                updateDto.ImageUrl = _fileStorage.GetPublicUrl(key);
            }

            _servantManager.Update(updateDto);

            return NoContent();
        }

        [HttpDelete("{id:int}")]
        public IActionResult DeleteById(int id)
        {
            _servantManager.Delete(id);
            return NoContent();
        }
    }
}