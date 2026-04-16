using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.API.Mapping;
using SunDaySchools.API.Requests;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;

namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    // [Authorize(Roles = "Servant")]
    public class MemberController : ControllerBase
    {
        private readonly IMemberManager _memberManager;
        private readonly IFileStorage _fileStorage;

        public MemberController(IMemberManager memberManager, IFileStorage fileStorage)
        {
            _memberManager = memberManager;
            _fileStorage = fileStorage;
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

            await _memberManager.AddAsync(memberDto, classroomId);
            return StatusCode(201, new { message = "Created Successfully" });
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