using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Manager;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.API.Requests;
using SunDaySchools.API.Mapping;
using Microsoft.AspNetCore.Authorization;
namespace SunDaySchools.API.Controllers


{
    [Route("api/[controller]")]
    [ApiController]
    public class servantController:ControllerBase
    {

        private readonly IServantManager _servantmanager;
        private readonly IFileStorage _fileStorage;

        public servantController(IServantManager servantmanager,IFileStorage filestorage)
        {

            _servantmanager = servantmanager;
            _fileStorage = filestorage;
        }

        [HttpGet]
        [Authorize]
        public ActionResult GetAll()
        {
            var servnants = _servantmanager.GetAll();
            if (servnants == null)
            {
                return NotFound();
            }
            return Ok(servnants);

        }
        [HttpGet("{id}")]
        public ActionResult GetById(int id)
        {
            var Servant = _servantmanager.GetById(id);
            return Ok(Servant);
        }


        [HttpPost]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> AddServant([FromForm]ServantAddFormRequest form , CancellationToken ct) 
        
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
            _servantmanager.Add(dto);

            return StatusCode(201, new { message = "Created Successfully" });



        }



        [HttpPut("{id}")]
        public ActionResult Update(int id, ServantUpdateDTO dto)
        {
            if (dto == null || id != dto.Id)
                return BadRequest();

            try
            {
                _servantmanager.Update(dto);
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

            _servantmanager.Delete(id);
            return NoContent();
        }
    }
}
