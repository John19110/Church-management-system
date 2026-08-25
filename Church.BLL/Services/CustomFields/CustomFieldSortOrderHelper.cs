using Church.DAL.Models.CustomFields;
using Church.DAL.Repository.Interfaces;

namespace Church.BLL.Services.CustomFields
{
    /// <summary>
    /// Assigns consistent <see cref="CustomFieldDefinition.SortOrder"/> values (step of 10).
    /// </summary>
    public static class CustomFieldSortOrderHelper
    {
        public const int Step = 10;

        public static int SortOrderForPosition(int oneBasedPosition) =>
            Math.Max(1, oneBasedPosition) * Step;

        public static async Task<int> GetDefaultLastPositionAsync(
            ICustomFieldRepository repository,
            string entityName,
            CancellationToken cancellationToken = default)
        {
            var count = await CountActiveProvisionedFieldsAsync(repository, entityName, cancellationToken);
            return count + 1;
        }

        public static async Task<int> CountActiveProvisionedFieldsAsync(
            ICustomFieldRepository repository,
            string entityName,
            CancellationToken cancellationToken = default)
        {
            var definitions = await repository.GetDefinitionsByEntityAsync(entityName, includeInactive: false);
            return definitions.Count(d => d.Id > 0);
        }

        /// <summary>
        /// Reorders active provisioned fields so <paramref name="fieldId"/> (if any) sits at
        /// <paramref name="targetPosition"/> (1-based), then reassigns sort orders.
        /// </summary>
        public static async Task ApplyDisplayPositionAsync(
            ICustomFieldRepository repository,
            string entityName,
            int? fieldId,
            int targetPosition,
            CancellationToken cancellationToken = default)
        {
            var tracked = (await repository.GetTrackedDefinitionsByEntityAsync(
                    entityName,
                    includeInactive: false))
                .Where(d => d.Id > 0)
                .OrderBy(d => d.SortOrder)
                .ThenBy(d => d.DisplayName, StringComparer.OrdinalIgnoreCase)
                .ToList();

            CustomFieldDefinition? moving = null;
            if (fieldId is int id)
            {
                moving = tracked.FirstOrDefault(d => d.Id == id);
                if (moving != null)
                    tracked.Remove(moving);
            }

            var insertIndex = Math.Clamp(targetPosition - 1, 0, tracked.Count);
            if (moving != null)
                tracked.Insert(insertIndex, moving);

            var now = DateTime.UtcNow;
            for (var i = 0; i < tracked.Count; i++)
            {
                tracked[i].SortOrder = SortOrderForPosition(i + 1);
                tracked[i].UpdatedAt = now;
            }

            if (tracked.Count > 0)
                await repository.SaveChangesAsync(cancellationToken);
        }
    }

}
