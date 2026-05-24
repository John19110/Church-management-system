using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.DTOS.Meeting;
using SunDaySchools.BLL.DTOS.MeetingDtos;
using SunDaySchools.BLL.Manager.Implementations;
using SunDaySchools.BLL.DTOS.UnifiedForms;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.BLL.Services.UnifiedForms;
using SunDaySchools.DAL.Models.CustomFields;
using System.Net.Mime;

namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class MeetingController : ControllerBase
    {
        private readonly IMeetingManager _meetingManager;
        private readonly IUnifiedEntityFormManager _unifiedFormManager;

        public MeetingController(
            IMeetingManager meetingManager,
            IUnifiedEntityFormManager unifiedFormManager)
        {
            _meetingManager = meetingManager;
            _unifiedFormManager = unifiedFormManager;
        }

        [HttpPost]
        public async Task<IActionResult> Create(MeetingAddDTO meeting)
        {
            await _meetingManager.AddMeeting(meeting);
            return Ok(new { message = "Meeting added successfully" });



        }

        [HttpGet("select")]
        //[Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> GetMeetingsForSelection()
        {
            var result = await _meetingManager.GetMeetingsForSelection();
            return Ok(result);
        }

        [HttpGet("visible")]
        //[Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> GetvisibleMeetings()
        {
            var result = await _meetingManager.GetVisibleMeetings();
            return Ok(result);
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
        public async Task<IActionResult> SaveFormData(int id, [FromBody] SaveEntityFormDto request)
        {
            if (id <= 0) return BadRequest("Meeting id must be a positive integer.");
            if (request == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    [""] = new[] { "Request body is required." }
                });
            await _unifiedFormManager.SaveFormDataAsync(CustomFieldEntityNames.Meeting, id, request);
            return Ok(new { message = "Form saved." });
        }

        [HttpPut("{id:int}")]
        //[Authorize(Roles = "SuperAdmin")]
        public async Task<IActionResult> UpdateMeeting(
            int id,
            [FromBody] MeetingUpdateDto dto,
            [FromQuery] bool generate = false)
        {
            await _meetingManager.UpdateMeeting(id, dto, generateDefaults: generate);
            return NoContent();
        }





    }
}