using Church.BLL.DTOS.UnifiedForms;
using Church.BLL.Services.UnifiedForms;

namespace Church.BLL.Manager.Interfaces
{
    public interface IUnifiedEntityFormManager
    {
        Task<EntityFormSchemaDto> GetFormSchemaAsync(string entityName, EntityFormMode mode = EntityFormMode.Edit);

        Task<EntityFormDataDto> GetFormDataAsync(string entityName, int entityId);

        Task SaveFormDataAsync(string entityName, int entityId, SaveEntityFormDto dto);

        /// <summary>
        /// Creates a minimal entity row then persists all admin-defined custom field values.
        /// </summary>
        Task<int> CreateEntityWithFormDataAsync(
            string entityName,
            SaveEntityFormDto dto,
            int? classroomIdForMember = null,
            int? meetingIdForClassroom = null);
    }
}
