using SunDaySchools.DAL.Models.CustomFields;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public interface ICustomFieldRepository
    {
        Task<IReadOnlyList<CustomFieldDefinition>> GetDefinitionsByEntityAsync(
            string entityName, bool includeInactive = false);

        Task<CustomFieldDefinition?> GetDefinitionByIdAsync(int id, bool includeOptions = true);

        Task<CustomFieldDefinition?> GetTrackedDefinitionByIdAsync(
            int id, bool includeOptions = true);

        Task<CustomFieldDefinition?> GetDefinitionByNameAsync(
            string entityName, string name);

        Task AddDefinitionAsync(CustomFieldDefinition definition);
        Task UpdateDefinitionAsync(CustomFieldDefinition definition);
        Task SaveChangesAsync(CancellationToken cancellationToken = default);

        Task<IReadOnlyList<CustomFieldDefinition>> GetTrackedDefinitionsByEntityAsync(
            string entityName, bool includeInactive = false);

        Task DeleteDefinitionAsync(int id);

        Task<IReadOnlyList<CustomFieldValue>> GetValuesAsync(string entityName, int entityId);
        Task<CustomFieldValue?> GetValueAsync(int definitionId, string entityName, int entityId);

        Task UpsertValuesAsync(IEnumerable<CustomFieldValue> values);

        Task<int> CountValuesForDefinitionAsync(int definitionId);
        Task<IReadOnlyList<string>> GetDistinctRawValuesAsync(int definitionId, int maxSample = 500);

        Task<bool> EntityExistsAsync(string entityName, int entityId);
    }
}
