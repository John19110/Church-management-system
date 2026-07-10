using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Church.BLL.Authorization;
using Church.BLL.DTOS;
using Church.BLL.DTOS.CustomFields;
using Church.BLL.DTOS.Meeting;
using Church.BLL.DTOS.MeetingDtos;
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
    public class MeetingController : ControllerBase
    {
        private readonly IMeetingManager _meetingManager;
        private readonly IUnifiedEntityFormManager _unifiedFormManager;
        private readonly ICustomFieldManager _customFieldManager;
        private readonly IMemberManager _memberManager;
        private readonly IServantManager _servantManager;

        public MeetingController(
            IMeetingManager meetingManager,
            IUnifiedEntityFormManager unifiedFormManager,
            ICustomFieldManager customFieldManager,
            IMemberManager memberManager,
            IServantManager servantManager)
        {
            _meetingManager = meetingManager;
            _unifiedFormManager = unifiedFormManager;
            _customFieldManager = customFieldManager;
            _memberManager = memberManager;
            _servantManager = servantManager;
        }

        [HttpPost]
        [Authorize(Roles = "SuperAdmin")]
        public async Task<IActionResult> Create(MeetingAddDTO meeting)
        {
            await _meetingManager.AddMeeting(meeting);
            return Ok(new { message = "Meeting added successfully" });
        }

        [HttpGet("select")]
        public async Task<IActionResult> GetMeetingsForSelection()
        {
            var result = await _meetingManager.GetMeetingsForSelection();
            return Ok(result);
        }

        [HttpGet("visible")]
        public async Task<IActionResult> GetvisibleMeetings()
        {
            var result = await _meetingManager.GetVisibleMeetings();
            return Ok(result);
        }

        /// <summary>System + custom field metadata for Meeting (admin configuration screen).</summary>
        [HttpGet("field-definitions")]
        [Authorize(Policy = CustomFieldPolicies.ReadDefinitions)]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<IReadOnlyList<EntityFieldDefinitionDto>>> GetFieldDefinitions(
            [FromQuery] bool includeInactive = true)
        {
            var defs = await _customFieldManager.GetDefinitionsByEntityAsync(
                CustomFieldEntityNames.Meeting,
                includeInactive);
            return Ok(defs.Select(CustomFieldDefinitionReadMapper.ToFieldDefinitionSummary).ToList());
        }

        [HttpGet("form-schema")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<EntityFormSchemaDto>> GetFormSchema([FromQuery] string mode = "Edit")
        {
            var formMode = Enum.TryParse<EntityFormMode>(mode, ignoreCase: true, out var parsed)
                ? parsed : EntityFormMode.Edit;
            return Ok(await _unifiedFormManager.GetFormSchemaAsync(CustomFieldEntityNames.Meeting, formMode));
        }

        [HttpGet("{id:int}/form-data")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<EntityFormDataDto>> GetFormData(int id)
        {
            if (id <= 0) return BadRequest("Meeting id must be a positive integer.");
            return Ok(await _unifiedFormManager.GetFormDataAsync(CustomFieldEntityNames.Meeting, id));
        }

        [HttpPut("{id:int}/form-data")]
        [Consumes(MediaTypeNames.Application.Json)]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> SaveFormData(int id, [FromBody] SaveEntityFormDto request)
        {
            if (id <= 0) return BadRequest("Meeting id must be a positive integer.");
            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);
            if (request == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    [""] = new[] { "Request body is required." }
                });
            await _unifiedFormManager.SaveFormDataAsync(CustomFieldEntityNames.Meeting, id, request);
            return Ok(new { message = "Form saved." });
        }

        [HttpPut("{id:int}")]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> UpdateMeeting(
            int id,
            [FromBody] MeetingUpdateDto dto,
            [FromQuery] bool generate = false)
        {
            await _meetingManager.UpdateMeeting(id, dto, generateDefaults: generate);
            return NoContent();
        }

        [HttpDelete("{id:int}")]
        [Authorize(Roles = "SuperAdmin")]
        public async Task<IActionResult> DeleteMeeting(int id)
        {
            if (id <= 0) return BadRequest("Meeting id must be a positive integer.");
            await _meetingManager.DeleteMeetingAsync(id);
            return NoContent();
        }

        /// <summary>Returns only the members assigned to a specific meeting.</summary>
        [HttpGet("{meetingId:int}/members")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<IEnumerable<MemberReadDTO>>> GetMembersByMeeting(int meetingId)
        {
            if (meetingId <= 0) return BadRequest("Meeting id must be a positive integer.");
            var members = await _memberManager.GetByMeetingIdAsync(meetingId);
            return Ok(members);
        }

        /// <summary>Returns only the servants assigned to a specific meeting.</summary>
        [HttpGet("{meetingId:int}/servants")]
        [Authorize(Roles = "Admin,SuperAdmin")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<IEnumerable<ServantReadDTO>>> GetServantsByMeeting(int meetingId)
        {
            if (meetingId <= 0) return BadRequest("Meeting id must be a positive integer.");
            var servants = await _servantManager.GetByMeetingIdAsync(meetingId);
            return Ok(servants);
        }
    }
}
