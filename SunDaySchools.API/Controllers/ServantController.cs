using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.API.Mapping;
using SunDaySchools.API.Requests;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.BLL.Application.Servants;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Authorization;
using SunDaySchools.BLL.DTOS.CustomFields;
using SunDaySchools.BLL.DTOS.UnifiedForms;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.BLL.Services.UnifiedForms;
using SunDaySchools.BLL.Services.UnifiedForms;
using SunDaySchools.DAL.Models.CustomFields;
using System.Net.Mime;

namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ServantController : ControllerBase
    {
        private readonly IServantManager _servantManager;
        private readonly IServantProfileService _servantProfileService;
        private readonly IFileStorage _fileStorage;
        private readonly IWebHostEnvironment _env;
        private readonly IUnifiedEntityFormManager _unifiedFormManager;
        private readonly ICustomFieldManager _customFieldManager;

        public ServantController(
            IServantManager servantManager,
            IServantProfileService servantProfileService,
            IFileStorage fileStorage,
            IWebHostEnvironment env,
            IUnifiedEntityFormManager unifiedFormManager,
            ICustomFieldManager customFieldManager)
        {
            _servantManager = servantManager;
            _servantProfileService = servantProfileService;
            _fileStorage = fileStorage;
            _env = env;
            _unifiedFormManager = unifiedFormManager;
            _customFieldManager = customFieldManager;
        }

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

        [HttpGet("field-definitions")]
        [Authorize(Policy = CustomFieldPolicies.ReadDefinitions)]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<IReadOnlyList<EntityFieldDefinitionDto>>> GetFieldDefinitions(
            [FromQuery] bool includeInactive = true)
        {
            var defs = await _customFieldManager.GetDefinitionsByEntityAsync(
                CustomFieldEntityNames.Servant,
                includeInactive);
            return Ok(defs.Select(CustomFieldDefinitionReadMapper.ToFieldDefinitionSummary).ToList());
        }

        [HttpGet("form-schema")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<EntityFormSchemaDto>> GetFormSchema([FromQuery] string mode = "Edit")
        {
            var formMode = Enum.TryParse<EntityFormMode>(mode, ignoreCase: true, out var parsed)
                ? parsed : EntityFormMode.Edit;
            return Ok(await _unifiedFormManager.GetFormSchemaAsync(CustomFieldEntityNames.Servant, formMode));
        }

        [HttpGet("{id:int}/form-data")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<EntityFormDataDto>> GetFormData(int id)
        {
            if (id <= 0) return BadRequest("Servant id must be a positive integer.");
            return Ok(await _unifiedFormManager.GetFormDataAsync(CustomFieldEntityNames.Servant, id));
        }

        [HttpPut("{id:int}/form-data")]
        [Consumes(MediaTypeNames.Application.Json)]
        public async Task<IActionResult> SaveFormData(int id, [FromBody] SaveEntityFormDto request)
        {
            if (id <= 0) return BadRequest("Servant id must be a positive integer.");
            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);
            if (request == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    [""] = new[] { "Request body is required." }
                });
            await _unifiedFormManager.SaveFormDataAsync(CustomFieldEntityNames.Servant, id, request);
            return Ok(new { message = "Form saved." });
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

        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile(CancellationToken ct)
        {
            var profile = await _servantProfileService.GetForCurrentUserAsync(ct);
            return Ok(profile);
        }

        [Authorize(Roles = "Servant")]
        [HttpPut("profile")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UpdateProfile(
            [FromForm] ServantProfileFormRequest form,
            CancellationToken ct)
        {
            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);

            var command = new UpdateServantProfileCommand
            {
                Name = form.Name,
                PhoneNumber = form.PhoneNumber,
                BirthDate = form.BirthDate,
                JoiningDate = form.JoiningDate,
                ChurchId = form.ChurchId,
                MeetingId = form.MeetingId,
                ClassroomIds = form.ClassroomIds
            };

            if (form.Image is not null && form.Image.Length > 0)
            {
                var key = await _fileStorage.SaveImageAsync(form.Image, ct, "servants");
                command.ImageFileName = key;
                command.ImageUrl = _fileStorage.GetPublicUrl(key);
            }

            await _servantProfileService.UpdateForCurrentUserAsync(command, ct);
            return NoContent();
        }
    }
}
