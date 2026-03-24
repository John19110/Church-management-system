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
        public async Task<ActionResult> GetAll()
        {
            var servants = await _servantManager.GetAllAsync();
            return Ok(servants);
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult> GetById(int id)
        {
            var servant = await _servantManager.GetByIdAsync(id);

            if (servant == null)
                throw new NotFoundException($"Servant with id {id} not found.");

            return Ok(servant);
        }

        [HttpGet("select")]
        //[Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> GetServantsForSelection()
        {
            var result = await _servantManager.GetServantsForSelection();
            return Ok(result);
        }

        [HttpPut("{id:int}")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Update(int id, [FromForm] ServantFormRequest form, CancellationToken ct)
        {
            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);

            var updateDto = form.ToUpdateDto();
            updateDto.Id = id;
            //updateDto.ApplicationUserId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (form.Image is not null && form.Image.Length > 0)
            {
                var key = await _fileStorage.SaveImageAsync(form.Image, ct, "servants");
                updateDto.ImageFileName = key;
                updateDto.ImageUrl = _fileStorage.GetPublicUrl(key);
            }

            await _servantManager.UpdateAsync(updateDto);

            return NoContent();
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteById(int id)
        {
            await _servantManager.DeleteAsync(id);
            return NoContent();
        }
    }
}