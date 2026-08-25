using Microsoft.Extensions.Logging;
using Church.BLL.Abstractions;
using Church.DAL.Abstractions;
using Church.DAL.Models.CustomFields;
using Church.DAL.Repository.Interfaces;

namespace Church.BLL.Services.UnifiedForms
{
    /// <summary>
    /// Seeds built-in model fields as tenant-scoped <see cref="CustomFieldDefinition"/> rows on first access.
    /// </summary>
    public static class EntityDefaultFieldProvisioner
    {
        public static async Task EnsureDefaultsAsync(
            ICustomFieldRepository repository,
            string entityName,
            ILogger? logger = null,
            ITenantContext? tenantContext = null,
            ICurrentUserContext? currentUser = null)
        {
            var templates = EntityDefaultFieldTemplates.GetTemplates(entityName);
            if (templates.Count == 0)
                return;

            var existingNames = await repository.GetDefinitionNamesByEntityAsync(entityName);
            var permanentlyDeletedNames =
                await repository.GetPermanentlyDeletedDefinitionNamesByEntityAsync(entityName);

            if (!CustomFieldProvisioningContext.TryGetChurchId(
                    tenantContext,
                    currentUser,
                    out var churchId))
            {
                logger?.LogWarning(
                    "Skipping default field provisioning for {Entity}: ChurchId is not available on the request.",
                    entityName);
                return;
            }

            var meetingId = tenantContext?.MeetingId;
            var createdBy = currentUser?.UserId;

            foreach (var template in templates)
            {
                if (existingNames.Contains(template.Name))
                    continue;

                if (permanentlyDeletedNames.Contains(template.Name))
                    continue;

                var definition = new CustomFieldDefinition
                {
                    Name = template.Name,
                    DisplayName = template.DisplayName,
                    EntityName = entityName,
                    DataType = template.DataType,
                    IsRequired = template.IsRequired,
                    IsActive = true,
                    IsReadOnly = template.IsReadOnly,
                    IsHidden = template.IsHidden,
                    SortOrder = template.SortOrder,
                    Placeholder = template.Placeholder,
                    ValidationRegex = template.ValidationRegex,
                    ChurchId = churchId,
                    MeetingId = meetingId,
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = createdBy,
                };

                try
                {
                    await repository.AddDefinitionAsync(definition);
                    existingNames.Add(template.Name);
                    logger?.LogInformation(
                        "Provisioned default field {Field} for entity {Entity}",
                        template.Name,
                        entityName);
                }
                catch (Exception ex)
                {
                    logger?.LogWarning(
                        ex,
                        "Failed to provision default field {Field} for entity {Entity}",
                        template.Name,
                        entityName);
                }
            }
        }
    }
}
