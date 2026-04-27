using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.DTOS.ChurchDtos;
using SunDaySchools.BLL.Manager.Interfaces;

namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ChurchController : ControllerBase
    {
        private readonly IChurchManager _churchManager;

        public ChurchController(IChurchManager churchManager)
        {
            _churchManager = churchManager;
        }

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetById(int id)
        {
            var dto = await _churchManager.GetByIdAsync(id);
            return Ok(dto);
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(
            int id,
            [FromBody] ChurchUpdateDTO dto,
            [FromQuery] bool generate = false)
        {
            await _churchManager.UpdateAsync(id, dto, generateDefaults: generate);
            return NoContent();
        }
    }
}

