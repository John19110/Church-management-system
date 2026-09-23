using System.Net.Mime;
using Church.BLL.Authorization;
using Church.BLL.DTOS.CustomFeatures;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Church.API.Controllers
{
    [Route("api/custom-features")]
    [ApiController]
    [Authorize]
    [Produces(MediaTypeNames.Application.Json)]
    public class CustomFeatureController : ControllerBase
    {
        private readonly ICustomFeatureManager _manager;

        public CustomFeatureController(ICustomFeatureManager manager)
        {
            _manager = manager;
        }

        [HttpGet]
        public async Task<ActionResult<IReadOnlyList<CustomFeatureReadDto>>> GetFeatures(
            [FromQuery] bool includeInactive = false)
        {
            return Ok(await _manager.GetFeaturesAsync(includeInactive));
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<CustomFeatureReadDto>> GetFeature(int id)
        {
            var feature = await _manager.GetFeatureByIdAsync(id);
            return feature == null ? NotFound() : Ok(feature);
        }

        [HttpPost]
        [Consumes(MediaTypeNames.Application.Json)]
        [Authorize(Policy = CustomFeaturePolicies.ManageMetadata)]
        public async Task<ActionResult<CustomFeatureReadDto>> CreateFeature(
            [FromBody] CustomFeatureCreateDto request)
        {
            EnsureBody(request);
            var created = await _manager.CreateFeatureAsync(request);
            return CreatedAtAction(nameof(GetFeature), new { id = created.Id }, created);
        }

        [HttpPut("{id:int}")]
        [Consumes(MediaTypeNames.Application.Json)]
        [Authorize(Policy = CustomFeaturePolicies.ManageMetadata)]
        public async Task<ActionResult<CustomFeatureReadDto>> UpdateFeature(
            int id,
            [FromBody] CustomFeatureUpdateDto request)
        {
            EnsureBody(request);
            return Ok(await _manager.UpdateFeatureAsync(id, request));
        }

        [HttpDelete("{id:int}")]
        [Authorize(Policy = CustomFeaturePolicies.ManageMetadata)]
        public async Task<IActionResult> DeleteFeature(int id)
        {
            await _manager.DeleteFeatureAsync(id);
            return Ok(new { message = "Feature permanently deleted." });
        }

        [HttpGet("{featureId:int}/entities")]
        public async Task<ActionResult<IReadOnlyList<CustomEntityReadDto>>> GetEntities(
            int featureId,
            [FromQuery] bool includeInactive = false)
        {
            return Ok(await _manager.GetEntitiesAsync(featureId, includeInactive));
        }

        [HttpPost("{featureId:int}/entities")]
        [Consumes(MediaTypeNames.Application.Json)]
        [Authorize(Policy = CustomFeaturePolicies.ManageMetadata)]
        public async Task<ActionResult<CustomEntityReadDto>> CreateEntity(
            int featureId,
            [FromBody] CustomEntityCreateDto request)
        {
            EnsureBody(request);
            var created = await _manager.CreateEntityAsync(featureId, request);
            return CreatedAtAction("GetEntity", "CustomEntity", new { id = created.Id }, created);
        }

        private static void EnsureBody(object? request)
        {
            if (request == null)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    [""] = new[] { "Request body is required and must be valid JSON." }
                });
            }
        }
    }
}
