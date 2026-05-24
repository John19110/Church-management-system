using SunDaySchools.BLL.DTOS.UnifiedForms;
using SunDaySchools.BLL.Services.UnifiedForms;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface IUnifiedEntityFormManager
    {
        Task<EntityFormSchemaDto> GetFormSchemaAsync(string entityName, EntityFormMode mode = EntityFormMode.Edit);

        Task<EntityFormDataDto> GetFormDataAsync(string entityName, int entityId);

        Task SaveFormDataAsync(string entityName, int entityId, SaveEntityFormDto dto);
    }
}
