using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.ClsssroomDtos;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Implementations;
using SunDaySchools.BLL.DTOS.UnifiedForms;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.BLL.Services.UnifiedForms;
using SunDaySchools.DAL.Models.CustomFields;
using System.Net.Mime;
using System;
using System.Security.Claims;
using System.Threading.Tasks;



namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ClassroomController : ControllerBase
    {
        private readonly IClassroomManager _classroomManager;
        private readonly IServantManager _servantManager;
        private readonly IMemberManager _memberManager;
        private readonly IUnifiedEntityFormManager _unifiedFormManager;

        public ClassroomController(
            IClassroomManager classroomManager,
            IServantManager servantManager,
            IMemberManager memberManager,
            IUnifiedEntityFormManager unifiedFormManager)
        {
            _classroomManager = classroomManager;
            _servantManager = servantManager;
            _memberManager = memberManager;
            _unifiedFormManager = unifiedFormManager;
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