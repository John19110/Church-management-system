using Church.BLL.DTOS.UnifiedForms;
using Church.DAL.Models.CustomFields;

namespace Church.BLL.Services.UnifiedForms
{
    /// <summary>
    /// Shared rules for which custom field definitions appear on forms and detail screens.
    /// </summary>
    public static class EntityActiveFieldSchemaBuilder
    {
        public static HashSet<string> BuildSuppressedTemplateKeys(
            string entityName,
            IReadOnlyList<CustomFieldDefinition> definitions) =>
            definitions
                .Where(d => EntityDefaultFieldTemplates.IsBuiltInField(entityName, d.Name)
                    && (!d.IsActive || d.IsPermanentlyDeleted))
                .Select(d => d.Name)
                .ToHashSet(StringComparer.OrdinalIgnoreCase);

        public static List<UnifiedFieldDefinitionDto> BuildActiveUnifiedFields(
            IReadOnlyList<CustomFieldDefinition> definitions,
            Func<CustomFieldDefinition, UnifiedFieldDefinitionDto?> mapDefinition) =>
            definitions
                .Where(IsVisibleActiveDefinition)
                .Select(mapDefinition)
                .Where(f => f != null)
                .Cast<UnifiedFieldDefinitionDto>()
                .ToList();

        public static bool IsVisibleActiveDefinition(CustomFieldDefinition definition) =>
            definition.IsActive
            && !definition.IsHidden
            && !definition.IsPermanentlyDeleted;
    }

}
