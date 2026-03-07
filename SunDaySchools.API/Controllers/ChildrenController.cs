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
    public class ChildrenController : ControllerBase
    {
        private readonly IChildManager _childmanager;
        private readonly IFileStorage _fileStorage;

        public ChildrenController(IChildManager childmanager, IFileStorage fileStorage)
        {
            _childmanager = childmanager;
            _fileStorage = fileStorage;
        }

        [HttpGet]
        public ActionResult GetAll()
        {        
            var children = _childmanager.GetAll();

            if (!children.Any())
                throw new NotFoundException($"No Children found.");

            return Ok(children);
        }


        [HttpGet("classroom/{classroomId}")]
        public ActionResult GetSpecificClassroom(int classroomId)
        {

            var Children = _childmanager.GetSpecificClassroom(classroomId);

            if (Children != null)
            {
                return Ok(Children);
            }

              throw new NotFoundException($"Child with for class {classroomId} not found.");
        
        }


        [HttpGet("{id}")]
        public ActionResult GetById(int id)
        
        {
            
                var child = _childmanager.GetById(id);
                if (child != null)
                {
                    return Ok(child);
                }
            throw new NotFoundException($"Child with id {id} not found.");

        }

        [HttpPost]
        public async Task<IActionResult> Create(ChildAddDTO childdto)
        {
            if (childdto == null)
            {
                var errors = new Dictionary<string, string[]>
                {
                    ["childdto"] = new[] { "The request body cannot be empty." }
                };
                throw new ValidationException(errors);
            }

            _childmanager.Add(childdto);
            return StatusCode(201, new { message = "Created Successfully" });
        }

        [HttpPut("{id}")]
        public ActionResult Update(int id, ChildUpdateDTO dto)
        {
            if (dto == null)
            {
                var errors = new Dictionary<string, string[]>
                {
                    ["childdto"] = new[] { "The request body cannot be empty." }
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

            _childmanager.Update(dto); 
            return NoContent();
        }

        [HttpDelete("{id}")]
        public ActionResult DeletebyId(int id)
        {
            
            _childmanager.Delete(id);
            return NoContent();
        }
    }
    }
