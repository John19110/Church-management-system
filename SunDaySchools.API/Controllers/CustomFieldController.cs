using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.Authorization;
using SunDaySchools.BLL.DTOS.CustomFields;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Models.CustomFields;
using System.Net.Mime;

namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    [Produces(MediaTypeNames.Application.Json)]
    public class CustomFieldController : ControllerBase
    {
        private readonly ICustomFieldManager _customFieldManager;

        public CustomFieldController(ICustomFieldManager customFieldManager)
        {
            _customFieldManager = customFieldManager;
        }

        /// <summary>Get active field definitions for an entity type (Member, Classroom, etc.).</summary>
        [HttpGet("definitions/{entityName}")]
        [Authorize(Policy = CustomFieldPolicies.ReadDefinitions)]
        public async Task<ActionResult<IReadOnlyList<CustomFieldDefinitionReadDto>>> GetDefinitions(
            string entityName,
            [FromQuery] bool includeInactive = false)
        {
            var result = await _customFieldManager.GetDefinitionsByEntityAsync(entityName, includeInactive);
            return Ok(result);
        }

        [HttpGet("definitions/id/{id:int}")]
        [Authorize(Policy = CustomFieldPolicies.ReadDefinitions)]
        public async Task<ActionResult<CustomFieldDefinitionReadDto>> GetDefinitionById(int id)
        {
            var result = await _customFieldManager.GetDefinitionByIdAsync(id);
            if (result == null)
                return NotFound();
            return Ok(result);
        }

        /// <summary>
        /// Create a custom field definition. Body must be JSON (camelCase properties, string enums).
        /// Example: { "displayName": "Baptism date", "entityName": "Member", "dataType": "Date", "isRequired": false }
        /// Internal <c>name</c> is optional; when omitted it is generated from <c>displayName</c>.
        /// </summary>
        [HttpPost("definitions")]
        [Consumes(MediaTypeNames.Application.Json)]
        [Authorize(Policy = CustomFieldPolicies.ManageDefinitions)]
        public async Task<ActionResult<CustomFieldDefinitionReadDto>> CreateDefinition(
            [FromBody] CustomFieldDefinitionCreateDto request)
        {
            if (request == null)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    [""] = new[] { "Request body is required and must be valid JSON." }
                });
            }

            var created = await _customFieldManager.CreateDefinitionAsync(request);
            return CreatedAtAction(nameof(GetDefinitionById), new { id = created.Id }, created);
        }

        [HttpPut("definitions/{id:int}")]
        [Consumes(MediaTypeNames.Application.Json)]
        [Authorize(Policy = CustomFieldPolicies.ManageDefinitions)]
        public async Task<ActionResult<CustomFieldDefinitionReadDto>> UpdateDefinition(
            int id,
            [FromBody] CustomFieldDefinitionUpdateDto request)
        {
            if (request == null)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    [""] = new[] { "Request body is required and must be valid JSON." }
                });
            }

            var updated = await _customFieldManager.UpdateDefinitionAsync(id, request);
            return Ok(updated);
        }

        [HttpPost("definitions/{id:int}/deactivate")]
        [Authorize(Policy = CustomFieldPolicies.ManageDefinitions)]
        public async Task<IActionResult> DeactivateDefinition(int id)
        {
            await _customFieldManager.DeactivateDefinitionAsync(id);
            return Ok(new { message = "Field deactivated." });
        }

        [HttpPost("definitions/{id:int}/activate")]
        [Authorize(Policy = CustomFieldPolicies.ManageDefinitions)]
        public async Task<IActionResult> ActivateDefinition(int id)
        {
            await _customFieldManager.ActivateDefinitionAsync(id);
            return Ok(new { message = "Field activated." });
        }

        [HttpDelete("definitions/{id:int}")]
        [Authorize(Policy = CustomFieldPolicies.ManageDefinitions)]
        public async Task<IActionResult> DeleteDefinition(int id)
        {
            await _customFieldManager.DeleteDefinitionAsync(id);
            return Ok(new { message = "Field permanently deleted." });
        }

        [HttpGet("definitions/{id:int}/check-type-change")]
        [Authorize(Policy = CustomFieldPolicies.ManageDefinitions)]
        public async Task<ActionResult<CustomFieldTypeChangeCheckDto>> CheckTypeChange(
            int id,
            [FromQuery] string newDataType)
        {
            if (!Enum.TryParse<CustomFieldDataType>(newDataType, ignoreCase: true, out var parsed))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["newDataType"] = new[] { $"Invalid data type '{newDataType}'." }
                });
            }

            var result = await _customFieldManager.CheckDataTypeChangeAsync(id, parsed);
            return Ok(result);
        }

        /// <summary>Definitions + current values for a specific entity instance.</summary>
        [HttpGet("entities/{entityName}/{entityId:int}")]
        [Authorize(Policy = CustomFieldPolicies.ReadDefinitions)]
        public async Task<ActionResult<EntityCustomFieldsReadDto>> GetEntityFields(
            string entityName,
            int entityId)
        {
            var result = await _customFieldManager.GetEntityFieldsAsync(entityName, entityId);
            return Ok(result);
        }

        [HttpPut("values")]
        [Consumes(MediaTypeNames.Application.Json)]
        [Authorize(Policy = CustomFieldPolicies.WriteValues)]
        public async Task<IActionResult> SaveValues([FromBody] SaveCustomFieldValuesDto request)
        {
            if (request == null)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    [""] = new[] { "Request body is required and must be valid JSON." }
                });
            }

            await _customFieldManager.SaveEntityValuesAsync(request);
            return Ok(new { message = "Custom field values saved." });
        }
    }
}
