using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.API.Mapping;
using SunDaySchools.API.Requests;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Authorization;
using SunDaySchools.BLL.DTOS.CustomFields;
using SunDaySchools.BLL.DTOS.UnifiedForms;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.BLL.Services.UnifiedForms;
using SunDaySchools.DAL.Models.CustomFields;
using System.Net.Mime;

namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    // [Authorize(Roles = "Servant")]
    public class MemberController : ControllerBase
    {
        private readonly IMemberManager _memberManager;
        private readonly IFileStorage _fileStorage;
        private readonly IUnifiedEntityFormManager _unifiedFormManager;
        private readonly ICustomFieldManager _customFieldManager;

        public MemberController(
            IMemberManager memberManager,
            IFileStorage fileStorage,
            IUnifiedEntityFormManager unifiedFormManager,
            ICustomFieldManager customFieldManager)
        {
            _memberManager = memberManager;
            _fileStorage = fileStorage;
            _unifiedFormManager = unifiedFormManager;
            _customFieldManager = customFieldManager;
        }


        [HttpPost("/api/classrooms/{classroomId}/members")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Create(int classroomId, [FromForm] MemberAddDTO memberDto)
        {
            if (memberDto == null)
            {
                var errors = new Dictionary<string, string[]>
                {
                    ["memberDto"] = new[] { "The request body cannot be empty." }
                };
                throw new ValidationException(errors);
            }

            var id = await _memberManager.AddAsync(memberDto, classroomId);
            return StatusCode(201, new MemberCreatedResponseDto
            {
                Id = id,
                Message = "Created successfully."
            });
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<MemberReadDTO>>> GetAll()
        {
            var members = await _memberManager.GetAllAsync();
            return Ok(members);
        }

        /// <summary>Literal segment must be registered before <c>{id}</c> so <c>/api/Member/select</c> is not bound as an integer route.</summary>
        // [Authorize(Roles = "Admin,SuperAdmin")]
        [HttpGet("select")]
        public async Task<IActionResult> GetMembersForSelection()
        {
            var result = await _memberManager.GetMembersForSelection();
            return Ok(result);
        }

        /// <summary>Returns members for a classroom. 200 with an empty array if the classroom exists but has no members; 404 only if the classroom does not exist.</summary>
        /// <summary>Unified form schema: built-in + custom fields in one list.</summary>
        [HttpGet("field-definitions")]
        [Authorize(Policy = CustomFieldPolicies.ReadDefinitions)]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<IReadOnlyList<EntityFieldDefinitionDto>>> GetFieldDefinitions(
            [FromQuery] bool includeInactive = true)
        {
            var defs = await _customFieldManager.GetDefinitionsByEntityAsync(
                CustomFieldEntityNames.Member,
                includeInactive);
            return Ok(defs.Select(CustomFieldDefinitionReadMapper.ToFieldDefinitionSummary).ToList());
        }

        [HttpGet("form-schema")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<EntityFormSchemaDto>> GetFormSchema(
            [FromQuery] string mode = "Edit")
        {
            var formMode = Enum.TryParse<EntityFormMode>(mode, ignoreCase: true, out var parsed)
                ? parsed
                : EntityFormMode.Edit;
            return Ok(await _unifiedFormManager.GetFormSchemaAsync(
                CustomFieldEntityNames.Member, formMode));
        }

        [HttpGet("{id:int}/form-data")]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<EntityFormDataDto>> GetFormData(int id)
        {
            if (id <= 0) return BadRequest("Member id must be a positive integer.");
            return Ok(await _unifiedFormManager.GetFormDataAsync(CustomFieldEntityNames.Member, id));
        }

        /// <summary>
        /// Creates a member using only admin-defined custom fields (multipart image optional via legacy create).
        /// </summary>
        [HttpPost("create-from-form")]
        [Consumes(MediaTypeNames.Application.Json)]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<object>> CreateFromForm(
            [FromQuery] int classroomId,
            [FromBody] SaveEntityFormDto request)
        {
            if (classroomId <= 0) return BadRequest("Classroom id must be a positive integer.");
            if (!ModelState.IsValid) return ValidationProblem(ModelState);
            if (request == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    [""] = new[] { "Request body is required." }
                });

            var id = await _unifiedFormManager.CreateEntityWithFormDataAsync(
                CustomFieldEntityNames.Member,
                request,
                classroomIdForMember: classroomId);
            return Ok(new { id, message = "Member created." });
        }

        [HttpPut("{id:int}/form-data")]
        [Consumes(MediaTypeNames.Application.Json)]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<IActionResult> SaveFormData(int id, [FromBody] SaveEntityFormDto request)
        {
            if (id <= 0) return BadRequest("Member id must be a positive integer.");
            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);
            if (request == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    [""] = new[] { "Request body is required." }
                });

            await _unifiedFormManager.SaveFormDataAsync(CustomFieldEntityNames.Member, id, request);
            return Ok(new { message = "Form saved." });
        }

        [HttpGet("classroom/{classroomId}")]
        public async Task<ActionResult<IEnumerable<MemberReadDTO>>> GetMembersByClassroom(int classroomId)
        {
            if (classroomId <= 0)
                return BadRequest("Classroom id must be a positive integer.");

            var members = await _memberManager.GetSpecificClassroomAsync(classroomId);
            return Ok(members);
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<MemberReadDTO>> GetById(int id)
        {
            if (id <= 0)
                return BadRequest("Member id must be a positive integer.");

            var member = await _memberManager.GetByIdAsync(id);

            if (member != null)
            {
                return Ok(member);
            }

            throw new NotFoundException($"Member with id {id} not found.");
        }
        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(int id, [FromBody] MemberUpdateDTO dto)
        {
            if (id <= 0)
                return BadRequest("Member id must be a positive integer.");

            if (dto == null)
            {
                var errors = new Dictionary<string, string[]>
                {
                    ["memberDto"] = new[] { "The request body cannot be empty." }
                };
                throw new ValidationException(errors);
            }

            if (id != dto.Id)
            {
                var errors = new Dictionary<string, string[]>
                {
                    ["id"] = new[] { "The ID in the URL does not match the ID in the request body." }
                };
                throw new ValidationException(errors);
            }

            await _memberManager.UpdateAsync(dto);
            return NoContent();
        }

        [HttpPut("{id:int}/form")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UpdateWithForm(int id, [FromForm] MemberFormRequest form, CancellationToken ct)
        {
            if (id <= 0)
                return BadRequest("Member id must be a positive integer.");

            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);

            var existing = await _memberManager.GetByIdAsync(id);
            if (existing == null)
                throw new NotFoundException($"Member with id {id} not found.");

            // Map form => update DTO (partial updates allowed by nulls)
            var dto = new MemberUpdateDTO
            {
                Id = id,
                Name1 = form.Name1,
                Name2 = form.Name2,
                Name3 = form.Name3,
                Gender = form.Gender,
                Address = form.Address,
                DateOfBirth = form.DateOfBirth,
                JoiningDate = form.JoiningDate,
                SpiritualDateOfBirth = form.SpiritualDateOfBirth,
                LastAttendanceDate = form.LastAttendanceDate,
                IsDiscipline = form.IsDiscipline,
                TotalNumberOfDaysAttended = form.TotalNumberOfDaysAttended,
                Notes = form.Notes,
                BrothersNames = form.BrothersNames,
                HaveBrothers = form.HaveBrothers,
                PhoneNumbers = form.PhoneNumbers,
                ClassroomId = form.ClassroomId,
            };

            // Allow image update
            if (form.Image is not null && form.Image.Length > 0)
            {
                var key = await _fileStorage.SaveImageAsync(form.Image, ct, "members");
                // MemberUpdateDTO currently doesn't have image fields; manager will set entity directly later.
                // We'll set image onto entity in manager by reading IFormFile? Not available there, so we do it here.
                // Use repository directly through manager update mapping: we'll extend MemberManager to accept image updates via a new method.
                await _memberManager.UpdateImageAsync(id, key, _fileStorage.GetPublicUrl(key));
            }

            await _memberManager.UpdateAsync(dto);
            return NoContent();
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteById(int id)
        {
            if (id <= 0)
                return BadRequest("Member id must be a positive integer.");

            await _memberManager.DeleteAsync(id);
            return NoContent();
        }
    }
}