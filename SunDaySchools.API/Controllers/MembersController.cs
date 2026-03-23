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
    public class MembersController : ControllerBase
    {
        private readonly IMemberManager _memberManager;
        private readonly IFileStorage _fileStorage;

        public MembersController(IMemberManager memberManager, IFileStorage fileStorage)
        {
            _memberManager = memberManager;
            _fileStorage = fileStorage;
        }


        [HttpPost]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Create([FromForm] MemberAddDTO memberDto)
        {
            if (memberDto == null)
            {
                var errors = new Dictionary<string, string[]>
                {
                    ["memberDto"] = new[] { "The request body cannot be empty." }
                };
                throw new ValidationException(errors);
            }

            await _memberManager.AddAsync(memberDto);
            return StatusCode(201, new { message = "Created Successfully" });
        }



        [HttpGet]
        public async Task<ActionResult<IEnumerable<MemberReadDTO>>> GetAll()
        {
            var members = await _memberManager.GetAllAsync();
            return Ok(members);
        }

        [HttpGet("classroom/{classroomId}")]
        public async Task<ActionResult<IEnumerable<MemberReadDTO>>> GetSpecificClassroom(int classroomId)
        {
            var members = await _memberManager.GetSpecificClassroomAsync(classroomId);

            if (members != null && members.Any())
            {
                return Ok(members);
            }

            throw new NotFoundException($"Classroom {classroomId} not found or there are no members in it.");
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<MemberReadDTO>> GetById(int id)
        {
            var member = await _memberManager.GetByIdAsync(id);

            if (member != null)
            {
                return Ok(member);
            }

            throw new NotFoundException($"Member with id {id} not found.");
        }

        [HttpGet("members/select")]
        [Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> GetMembersForSelection()
        {
            var result = await _memberManager.GetMembersForSelection();
            return Ok(result);
        }
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] MemberUpdateDTO dto)
        {
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

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteById(int id)
        {
            await _memberManager.DeleteAsync(id);
            return NoContent();
        }
    }
}