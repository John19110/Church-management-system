using Church.DAL.Models.CustomFeatures;

namespace Church.DAL.Repository.Interfaces
{
    public interface ICustomFeatureRepository
    {
        Task<IReadOnlyList<CustomFeature>> GetFeaturesAsync(bool includeInactive = false);
        Task<CustomFeature?> GetFeatureByIdAsync(int id, bool includeEntities = true);
        Task<CustomFeature?> GetFeatureByNameAsync(string name);
        Task<int> CountFeaturesAsync();
        Task AddFeatureAsync(CustomFeature feature);
        Task DeleteFeatureAsync(CustomFeature feature);

        Task<IReadOnlyList<CustomEntity>> GetEntitiesByFeatureAsync(int featureId, bool includeInactive = false);
        Task<CustomEntity?> GetEntityByIdAsync(int id, bool includeFields = true, bool includePermissions = true);
        Task<int> CountEntitiesAsync(int featureId);
        Task AddEntityAsync(CustomEntity entity);
        Task DeleteEntityAsync(CustomEntity entity);

        Task<CustomEntityField?> GetFieldByIdAsync(int id, bool includeOptions = true);
        Task<int> CountFieldsAsync(int entityId);
        Task AddFieldAsync(CustomEntityField field);
        Task DeleteFieldAsync(CustomEntityField field);

        Task ReplacePermissionsAsync(int entityId, IReadOnlyList<CustomEntityPermission> permissions);

        Task<CustomEntityRecord?> GetRecordByIdAsync(int id, bool includeReferences = true);
        Task<(IReadOnlyList<CustomEntityRecord> Items, int Total)> GetRecordsAsync(
            int entityId,
            string? search,
            string? sortFieldName,
            bool sortDescending,
            int page,
            int pageSize);
        Task AddRecordAsync(CustomEntityRecord record);
        Task DeleteRecordAsync(CustomEntityRecord record);
        Task ReplaceRecordReferencesAsync(int recordId, IReadOnlyList<CustomEntityRecordReference> references);
        Task<bool> RecordReferencesTargetAsync(int targetRecordId);
        Task<bool> FieldHasReferencesAsync(int fieldId);
        Task<bool> MemberExistsAsync(int memberId);
        Task<bool> ServantExistsAsync(int servantId);
        Task<CustomEntityRecord?> GetRecordInEntityAsync(int entityId, int recordId);
        Task<IReadOnlyList<CustomEntityRecord>> GetRecordsByIdsAsync(int entityId, IReadOnlyList<int> recordIds);
        Task<IReadOnlyDictionary<int, string?>> GetMemberNamesAsync(IReadOnlyList<int> memberIds);
        Task<IReadOnlyDictionary<int, string?>> GetServantNamesAsync(IReadOnlyList<int> servantIds);
        Task<bool> ScalarValueExistsAsync(int entityId, string fieldName, string jsonValue, int? excludeRecordId);

        Task SaveChangesAsync(CancellationToken cancellationToken = default);
    }
}
