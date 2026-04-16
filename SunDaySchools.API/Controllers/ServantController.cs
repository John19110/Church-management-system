using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.API.Mapping;
using SunDaySchools.API.Requests;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Implementations;
using SunDaySchools.BLL.Manager.Interfaces;

namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ServantController : ControllerBase
    {
        private readonly IServantManager _servantManager;
        private readonly IFileStorage _fileStorage;
        private readonly IWebHostEnvironment _env;


        public ServantController(IServantManager servantManager, IFileStorage fileStorage, IWebHostEnvironment env)
        {
            _servantManager = servantManager;
            _fileStorage = fileStorage;
            _env = env;
        }

        // Add servant
        [HttpPost]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Create([FromForm(Name = "")] AdminAddServantDTO servant)
        {
            if (servant == null)
            {
                var errors = new Dictionary<string, string[]>
                {
                    ["servant"] = new[] { "The request body cannot be empty." }
                };
                throw new ValidationException(errors);
            }

            await _servantManager.AddAsync(servant, _env.WebRootPath);

            return StatusCode(201, new { message = "Created Successfully" });
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
            if (id <= 0)
                return BadRequest("Servant id must be a positive integer.");

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
            if (id <= 0)
                return BadRequest("Servant id must be a positive integer.");

            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);

            var updateDto = form.ToUpdateDto();
            updateDto.Id = id;

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
            if (id <= 0)
                return BadRequest("Servant id must be a positive integer.");

            var deleted = await _servantManager.DeleteAsync(id);
            if (!deleted)
                return NotFound();

            return NoContent();
        }
    }
}