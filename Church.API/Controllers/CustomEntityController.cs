using System.Net.Mime;
using Church.BLL.Authorization;
using Church.BLL.DTOS.CustomFeatures;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Church.API.Controllers
{
    [Route("api/custom-entities")]
    [ApiController]
    [Authorize]
    [Produces(MediaTypeNames.Application.Json)]
    public class CustomEntityController : ControllerBase
    {
        private readonly ICustomFeatureManager _manager;

        public CustomEntityController(ICustomFeatureManager manager)
        {
            _manager = manager;
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<CustomEntityReadDto>> GetEntity(int id)
        {
            var entity = await _manager.GetEntityByIdAsync(id);
            return entity == null ? NotFound() : Ok(entity);
        }

        [HttpPut("{id:int}")]
        [Consumes(MediaTypeNames.Application.Json)]
        [Authorize(Policy = CustomFeaturePolicies.ManageMetadata)]
        public async Task<ActionResult<CustomEntityReadDto>> UpdateEntity(
            int id,
            [FromBody] CustomEntityUpdateDto request)
        {
            EnsureBody(request);
            return Ok(await _manager.UpdateEntityAsync(id, request));
        }

        [HttpDelete("{id:int}")]
        [Authorize(Policy = CustomFeaturePolicies.ManageMetadata)]
        public async Task<IActionResult> DeleteEntity(int id)
        {
            await _manager.DeleteEntityAsync(id);
            return Ok(new { message = "Entity permanently deleted." });
        }

        [HttpPost("{entityId:int}/fields")]
        [Consumes(MediaTypeNames.Application.Json)]
        [Authorize(Policy = CustomFeaturePolicies.ManageMetadata)]
        public async Task<ActionResult<CustomEntityFieldReadDto>> CreateField(
            int entityId,
            [FromBody] CustomEntityFieldCreateDto request)
        {
            EnsureBody(request);
            var created = await _manager.CreateFieldAsync(entityId, request);
            return Ok(created);
        }

        [HttpPut("fields/{id:int}")]
        [Consumes(MediaTypeNames.Application.Json)]
        [Authorize(Policy = CustomFeaturePolicies.ManageMetadata)]
        public async Task<ActionResult<CustomEntityFieldReadDto>> UpdateField(
            int id,
            [FromBody] CustomEntityFieldUpdateDto request)
        {
            EnsureBody(request);
            return Ok(await _manager.UpdateFieldAsync(id, request));
        }

        [HttpDelete("fields/{id:int}")]
        [Authorize(Policy = CustomFeaturePolicies.ManageMetadata)]
        public async Task<IActionResult> DeleteField(int id)
        {
            await _manager.DeleteFieldAsync(id);
            return Ok(new { message = "Field permanently deleted." });
        }

        [HttpGet("{entityId:int}/permissions")]
        [Authorize(Policy = CustomFeaturePolicies.ManageMetadata)]
        public async Task<ActionResult<IReadOnlyList<CustomEntityPermissionDto>>> GetPermissions(int entityId)
        {
            return Ok(await _manager.GetPermissionsAsync(entityId));
        }

        [HttpPut("{entityId:int}/permissions")]
        [Consumes(MediaTypeNames.Application.Json)]
        [Authorize(Policy = CustomFeaturePolicies.ManageMetadata)]
        public async Task<ActionResult<IReadOnlyList<CustomEntityPermissionDto>>> UpdatePermissions(
            int entityId,
            [FromBody] IReadOnlyList<CustomEntityPermissionDto> request)
        {
            EnsureBody(request);
            return Ok(await _manager.UpdatePermissionsAsync(entityId, request));
        }

        [HttpGet("{entityId:int}/records")]
        [Authorize(Policy = CustomFeaturePolicies.UseRecords)]
        public async Task<ActionResult<CustomEntityRecordPageDto>> GetRecords(
            int entityId,
            [FromQuery] string? search,
            [FromQuery] string? sort,
            [FromQuery] bool descending = true,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            return Ok(await _manager.GetRecordsAsync(entityId, search, sort, descending, page, pageSize));
        }

        [HttpGet("{entityId:int}/records/{recordId:int}")]
        [Authorize(Policy = CustomFeaturePolicies.UseRecords)]
        public async Task<ActionResult<CustomEntityRecordReadDto>> GetRecord(int entityId, int recordId)
        {
            var record = await _manager.GetRecordByIdAsync(entityId, recordId);
            return record == null ? NotFound() : Ok(record);
        }

        [HttpPost("{entityId:int}/records")]
        [Consumes(MediaTypeNames.Application.Json)]
        [Authorize(Policy = CustomFeaturePolicies.UseRecords)]
        public async Task<ActionResult<CustomEntityRecordReadDto>> CreateRecord(
            int entityId,
            [FromBody] CustomEntityRecordWriteDto request)
        {
            EnsureBody(request);
            var created = await _manager.CreateRecordAsync(entityId, request);
            return CreatedAtAction(nameof(GetRecord), new { entityId, recordId = created.Id }, created);
        }

        [HttpPut("{entityId:int}/records/{recordId:int}")]
        [Consumes(MediaTypeNames.Application.Json)]
        [Authorize(Policy = CustomFeaturePolicies.UseRecords)]
        public async Task<ActionResult<CustomEntityRecordReadDto>> UpdateRecord(
            int entityId,
            int recordId,
            [FromBody] CustomEntityRecordWriteDto request)
        {
            EnsureBody(request);
            return Ok(await _manager.UpdateRecordAsync(entityId, recordId, request));
        }

        [HttpDelete("{entityId:int}/records/{recordId:int}")]
        [Authorize(Policy = CustomFeaturePolicies.UseRecords)]
        public async Task<IActionResult> DeleteRecord(int entityId, int recordId)
        {
            await _manager.DeleteRecordAsync(entityId, recordId);
            return Ok(new { message = "Record permanently deleted." });
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
