using Church.BLL.Authorization;
using Church.BLL.DTOS.OptionalModules;
using Church.BLL.Manager.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Net.Mime;

namespace Church.API.Controllers
{
    [Route("api/optional-modules")]
    [ApiController]
    [Authorize]
    public class OptionalModuleController : ControllerBase
    {
        private readonly IOptionalModuleManager _manager;

        public OptionalModuleController(IOptionalModuleManager manager)
        {
            _manager = manager;
        }

        [HttpGet]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<IReadOnlyList<OptionalModuleReadDto>>> GetAll()
        {
            return Ok(await _manager.GetModulesAsync());
        }

        [HttpPut("{moduleId}/enabled")]
        [Authorize(Policy = OptionalModulePolicies.ManageActivation)]
        [Produces(MediaTypeNames.Application.Json)]
        public async Task<ActionResult<OptionalModuleReadDto>> SetEnabled(
            string moduleId,
            [FromBody] SetOptionalModuleEnabledDto dto)
        {
            if (string.IsNullOrWhiteSpace(moduleId))
                return BadRequest("Module id is required.");

            var result = await _manager.SetEnabledAsync(moduleId, dto.IsEnabled);
            return Ok(result);
        }
    }
}
