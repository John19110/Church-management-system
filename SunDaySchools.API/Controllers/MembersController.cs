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
  //  [Authorize(Roles = "Servant")]
    public class MembersController : ControllerBase
    {
        private readonly IMemberManager _membermanager;
        private readonly IFileStorage _fileStorage;

        public MembersController(IMemberManager membermanager, IFileStorage fileStorage)
        {
            _membermanager = membermanager;
            _fileStorage = fileStorage;
        }

        [HttpGet]
        public ActionResult<IEnumerable<MemberReadDTO>> GetAll()
        {        
            var Members = _membermanager.GetAll();

  

            return Ok(Members);
        }


        [HttpGet("classroom/{classroomId}")]
        public ActionResult GetSpecificClassroom(int classroomId)
        {
            var Members = _membermanager.GetSpecificClassroom(classroomId);

            if (Members != null && Members.Any())
            {
                return Ok(Members);
            }

            throw new NotFoundException($"class {classroomId} not found or there is no Members in it.");
        }

        [HttpGet("{id}")]
        public ActionResult<MemberReadDTO> GetById(int id)
        
        {
            
                var member = _membermanager.GetById(id);
                if (member != null)
                {
                    return Ok(member);
                }
            throw new NotFoundException($"Member with id {id} not found.");

        }

        [HttpPost]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Create([FromForm] MemberAddDTO memberdto)
        {
            if (memberdto == null)
            {
                var errors = new Dictionary<string, string[]>
                {
                    ["memberdto"] = new[] { "The request body cannot be empty." }
                };
                throw new ValidationException(errors);
            }

            _membermanager.Add(memberdto);
            return StatusCode(201, new { message = "Created Successfully" });
        }

        [HttpPut("{id}")]
        public ActionResult Update(int id, MemberUpdateDTO dto)
        {
            if (dto == null)
            {
                var errors = new Dictionary<string, string[]>
                {
                    ["memberdto"] = new[] { "The request body cannot be empty." }
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

            _membermanager.Update(dto); 
            return NoContent();
        }

        [HttpDelete("{id}")]
        public ActionResult DeletebyId(int id)
        {
            
            _membermanager.Delete(id);
            return NoContent();
        }
    }
    }
