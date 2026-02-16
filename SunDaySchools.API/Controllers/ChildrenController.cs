using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Manager;
using SunDaySchools.API.Mapping;
using SunDaySchools.API.Requests; 
using SunDaySchools.API.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;


namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Servant")]
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
            var children = _childmanager.GetAll() ?? new List<ChildReadDTO>();
            if (children == null)
            {
                return NotFound();
            }
            return Ok(children);

        }

        [HttpGet("{id}")]
        public ActionResult GetById(int id)
        
        {
            {
                var child = _childmanager.GetById(id);
                if (child != null)
                {
                    return Ok(child);
                }
                else return NotFound();
            }
        }

        [HttpPost]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Create([FromForm] ChildAddFormRequest form, CancellationToken ct)
        {
            if (form == null) return BadRequest();

            var dto = form.ToDto();
            if (form.Image != null && form.Image.Length > 0)
            {
                var key = await _fileStorage.SaveChildImageAsync(form.Image, ct);
                dto.ImageFileName = key;
                dto.ImageUrl = _fileStorage.GetPublicUrl(key);
            }

            // 3) Manager uses AutoMapper to map DTO -> Entity
            _childmanager.Add(dto);

            return StatusCode(201, new { message = "Created Successfully" });
        }

        [HttpPut("{id}")]
        public ActionResult Update(int id, ChildUpdateDTO dto)
        {
            if (dto == null || id != dto.Id)
                return BadRequest();

            try
            {
                _childmanager.Update(dto);
                return NoContent(); // standard for PUT
            }
            catch (KeyNotFoundException)
            {
                return NotFound();
            }
        }


        [HttpDelete("{id}")]
        public ActionResult DeletebyId(int id)
        {

            _childmanager.Delete(id);
            return NoContent();
        }
    }
    }
