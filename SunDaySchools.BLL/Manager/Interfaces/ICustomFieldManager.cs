using SunDaySchools.BLL.DTOS.CustomFields;
using SunDaySchools.DAL.Models.CustomFields;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface ICustomFieldManager
    {
        Task<IReadOnlyList<CustomFieldDefinitionReadDto>> GetDefinitionsByEntityAsync(
            string entityName, bool includeInactive = false);

        Task<CustomFieldDefinitionReadDto?> GetDefinitionByIdAsync(int id);

        Task<CustomFieldDefinitionReadDto> CreateDefinitionAsync(CustomFieldDefinitionCreateDto dto);

        Task<CustomFieldDefinitionReadDto> UpdateDefinitionAsync(int id, CustomFieldDefinitionUpdateDto dto);

        Task DeactivateDefinitionAsync(int id);

        Task<CustomFieldTypeChangeCheckDto> CheckDataTypeChangeAsync(int id, CustomFieldDataType newDataType);

        Task<EntityCustomFieldsReadDto> GetEntityFieldsAsync(string entityName, int entityId);

        Task SaveEntityValuesAsync(SaveCustomFieldValuesDto dto);
    }
}
