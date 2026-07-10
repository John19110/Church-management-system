using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Church.BLL.DTOS;
using Church.BLL.DTOS.ClsssroomDtos;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Implementations;
using Church.BLL.Authorization;
using Church.BLL.DTOS.CustomFields;
using Church.BLL.DTOS.UnifiedForms;
using Church.BLL.Manager.Interfaces;
using Church.BLL.Services.UnifiedForms;
using Church.BLL.Services.UnifiedForms;
using Church.DAL.Models.CustomFields;
using System.Net.Mime;
using System;
using System.Security.Claims;
using System.Threading.Tasks;



namespace Church.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ClassroomController : ControllerBase
    {
        private readonly IClassroomManager _classroomManager;
        private readonly IServantManager _servantManager;
        private readonly IMemberManager _memberManager;
        private readonly IUnifiedEntityFormManager _unifiedFormManager;
        private readonly ICustomFieldManager _customFieldManager;

        public ClassroomController(
            IClassroomManager classroomManager,
            IServantManager servantManager,
            IMemberManager memberManager,
            IUnifiedEntityFormManager unifiedFormManager,
            ICustomFieldManager customFieldManager)
        {
            _classroomManager = classroomManager;
            _servantManager = servantManager;
            _memberManager = memberManager;
            _unifiedFormManager = unifiedFormManager;
            _customFieldManager = customFieldManager;
        }


        [HttpPost]
        public async Task<IActionResult> Create(ClassroomAddDTO classroom)
        {
            await _classroomManager.AddAsync(classroom);
            return Ok();
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(
            int id,
            [FromBody] ClassroomUpdateDTO dto,
            [FromQuery] bool generate = false)
        {
            await _classroomManager.UpdateAsync(id, dto, generateDefaults: generate);
            return NoContent();
        }

        [HttpDelete("{id:int}")]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> Delete(int id)
        {
            if (id <= 0) return BadRequest("Classroom id must be a positive integer.");
            await _classroomManager.DeleteAsync(id);
            return NoContent();
        }

        [HttpGet("visible")]
        public async Task<IActionResult> GetVisibleClassrooms([FromQuery] int? meetingId = null)
        {
            var result = await _classroomManager.GetVisibleClassrooms(meetingId);
            return Ok(result);
        }


        [HttpGet("select")]
        //[Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> GetClassroomsForSelection()
        {
            var result = await _classroomManager.GetClassroomsForSelection();
            return Ok(result);
        }

        /// <summary>System + custom field metadata for Classroom (admin configuration screen).</summary>
        [HttpGet("field-definitions")]
        [Authorize(Policy = CustomFieldPolicies.ReadDefinitions)]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<IReadOnlyList<EntityFieldDefinitionDto>>> GetFieldDefinitions(
            [FromQuery] bool includeInactive = true)
        {
            var defs = await _customFieldManager.GetDefinitionsByEntityAsync(
                CustomFieldEntityNames.Classroom,
                includeInactive);
            return Ok(defs.Select(CustomFieldDefinitionReadMapper.ToFieldDefinitionSummary).ToList());
        }

        [HttpGet("form-schema")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<EntityFormSchemaDto>> GetFormSchema([FromQuery] string mode = "Edit")
        {
            var formMode = Enum.TryParse<EntityFormMode>(mode, ignoreCase: true, out var parsed)
                ? parsed : EntityFormMode.Edit;
            return Ok(await _unifiedFormManager.GetFormSchemaAsync(CustomFieldEntityNames.Classroom, formMode));
        }

        [HttpGet("{id:int}/form-data")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<EntityFormDataDto>> GetFormData(int id)
        {
            if (id <= 0) return BadRequest("Classroom id must be a positive integer.");
            return Ok(await _unifiedFormManager.GetFormDataAsync(CustomFieldEntityNames.Classroom, id));
        }

        [HttpPost("create-from-form")]
        [Consumes(MediaTypeNames.Application.Json)]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<object>> CreateFromForm(
            [FromBody] SaveEntityFormDto request,
            [FromQuery] int? meetingId = null)
        {
            if (!ModelState.IsValid) return ValidationProblem(ModelState);
            if (request == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    [""] = new[] { "Request body is required." }
                });

            var id = await _unifiedFormManager.CreateEntityWithFormDataAsync(
                CustomFieldEntityNames.Classroom,
                request,
                meetingIdForClassroom: meetingId);
            return Ok(new { id, message = "Classroom created." });
        }

        [HttpPut("{id:int}/form-data")]
        [Consumes(MediaTypeNames.Application.Json)]
        public async Task<IActionResult> SaveFormData(int id, [FromBody] SaveEntityFormDto request)
        {
            if (id <= 0) return BadRequest("Classroom id must be a positive integer.");
            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);
            if (request == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    [""] = new[] { "Request body is required." }
                });
            await _unifiedFormManager.SaveFormDataAsync(CustomFieldEntityNames.Classroom, id, request);
            return Ok(new { message = "Form saved." });
        }





    }
}