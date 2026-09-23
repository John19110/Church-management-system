using Church.BLL.DTOS.CustomFeatures;

namespace Church.BLL.Manager.Interfaces
{
    public interface ICustomFeatureManager
    {
        Task<IReadOnlyList<CustomFeatureReadDto>> GetFeaturesAsync(bool includeInactive = false);
        Task<CustomFeatureReadDto?> GetFeatureByIdAsync(int id);
        Task<CustomFeatureReadDto> CreateFeatureAsync(CustomFeatureCreateDto dto);
        Task<CustomFeatureReadDto> UpdateFeatureAsync(int id, CustomFeatureUpdateDto dto);
        Task DeleteFeatureAsync(int id);

        Task<IReadOnlyList<CustomEntityReadDto>> GetEntitiesAsync(int featureId, bool includeInactive = false);
        Task<CustomEntityReadDto?> GetEntityByIdAsync(int id);
        Task<CustomEntityReadDto> CreateEntityAsync(int featureId, CustomEntityCreateDto dto);
        Task<CustomEntityReadDto> UpdateEntityAsync(int id, CustomEntityUpdateDto dto);
        Task DeleteEntityAsync(int id);

        Task<CustomEntityFieldReadDto> CreateFieldAsync(int entityId, CustomEntityFieldCreateDto dto);
        Task<CustomEntityFieldReadDto> UpdateFieldAsync(int id, CustomEntityFieldUpdateDto dto);
        Task DeleteFieldAsync(int id);

        Task<IReadOnlyList<CustomEntityPermissionDto>> GetPermissionsAsync(int entityId);
        Task<IReadOnlyList<CustomEntityPermissionDto>> UpdatePermissionsAsync(
            int entityId,
            IReadOnlyList<CustomEntityPermissionDto> permissions);

        Task<CustomEntityRecordPageDto> GetRecordsAsync(
            int entityId,
            string? search,
            string? sort,
            bool descending,
            int page,
            int pageSize);
        Task<CustomEntityRecordReadDto?> GetRecordByIdAsync(int entityId, int recordId);
        Task<CustomEntityRecordReadDto> CreateRecordAsync(int entityId, CustomEntityRecordWriteDto dto);
        Task<CustomEntityRecordReadDto> UpdateRecordAsync(int entityId, int recordId, CustomEntityRecordWriteDto dto);
        Task DeleteRecordAsync(int entityId, int recordId);
    }
}
