using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.API.Mapping;
using SunDaySchools.API.Requests;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
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
 
        public ActionResult GetAll()
        {
            var servnants = _servantmanager.GetAll();
            if (servnants == null)
            {
                throw new NotFoundException($"No Servants found.");
            }
            return Ok(servnants);

        }
        [HttpGet("{id}")]
        public ActionResult GetById(int id)
        {
            var Servant = _servantmanager.GetById(id);
            if (Servant==null)
            {
                throw new NotFoundException($"Servant with id {id} not found.");

            }
            return Ok(Servant);
        }


        [HttpPost]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> AddServant([FromForm]ServantFormRequest form , CancellationToken ct) 
        
        {
            if (form == null)
            {
                var errors = new Dictionary<string, string[]>
                {
                    ["childdto"] = new[] { "The request body cannot be empty." }
                };
                throw new ValidationException(errors);
            }
            ;

            var dto = form.ToAddDto();
            if (form.Image != null && form.Image.Length > 0)
            {
                var key = await _fileStorage.SaveImageAsync(form.Image, ct,"servants");
                dto.ImageFileName = key;
                dto.ImageUrl = _fileStorage.GetPublicUrl(key);
            }

            // 3) Manager uses AutoMapper to map DTO -> Entity
            _servantmanager.Add(dto);

            return StatusCode(201, new { message = "Created Successfully" });



        }



        [HttpPut("{id:int}")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Update(int id,[FromForm] ServantFormRequest form,CancellationToken ct )
        {


            // Map form fields -> update dto
            var updateDto = form.ToUpdateDto();
            updateDto.Id = id;


            // Optional image upload
            if (form.Image is not null && form.Image.Length > 0)
            {
                var key = await _fileStorage.SaveImageAsync(form.Image, ct, "servant");
                updateDto.ImageFileName = key;
                updateDto.ImageUrl = _fileStorage.GetPublicUrl(key);
            }

            try
            {
                _servantmanager.Update(updateDto);
                return NoContent();
            }
            catch (NotFoundException)
            {
                throw new NotFoundException($"Servant  not found.");
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
