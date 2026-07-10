using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Church.BLL.DTOS.ChurchDtos;
using Church.BLL.DTOS.UnifiedForms;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;
using Church.BLL.Services.UnifiedForms;
using Church.DAL.Models.CustomFields;
using System.Net.Mime;

namespace Church.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ChurchController : ControllerBase
    {
        private readonly IChurchManager _churchManager;
        private readonly IUnifiedEntityFormManager _unifiedFormManager;

        public ChurchController(
            IChurchManager churchManager,
            IUnifiedEntityFormManager unifiedFormManager)
        {
            _churchManager = churchManager;
            _unifiedFormManager = unifiedFormManager;
        }

        [HttpGet("form-schema")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<EntityFormSchemaDto>> GetFormSchema([FromQuery] string mode = "Edit")
        {
            var formMode = Enum.TryParse<EntityFormMode>(mode, ignoreCase: true, out var parsed)
                ? parsed : EntityFormMode.Edit;
            return Ok(await _unifiedFormManager.GetFormSchemaAsync(CustomFieldEntityNames.Church, formMode));
        }

        [HttpGet("{id:int}/form-data")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<EntityFormDataDto>> GetFormData(int id)
        {
            if (id <= 0) return BadRequest("Church id must be a positive integer.");
            return Ok(await _unifiedFormManager.GetFormDataAsync(CustomFieldEntityNames.Church, id));
        }

        [HttpPut("{id:int}/form-data")]
        [Consumes(MediaTypeNames.Application.Json)]
        public async Task<IActionResult> SaveFormData(int id, [FromBody] SaveEntityFormDto request)
        {
            if (id <= 0) return BadRequest("Church id must be a positive integer.");
            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);
            if (request == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    [""] = new[] { "Request body is required." }
                });
            await _unifiedFormManager.SaveFormDataAsync(CustomFieldEntityNames.Church, id, request);
            return Ok(new { message = "Form saved." });
        }

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetById(int id)
        {
            var dto = await _churchManager.GetByIdAsync(id);
            return Ok(dto);
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(
            int id,
            [FromBody] ChurchUpdateDTO dto,
            [FromQuery] bool generate = false)
        {
            await _churchManager.UpdateAsync(id, dto, generateDefaults: generate);
            return NoContent();
        }
    }
}

