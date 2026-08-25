using Church.BLL.DTOS.UnifiedForms;

namespace Church.BLL.Services.UnifiedForms
{
    public static class EntityFormSchemaRegistry
    {
        public static IReadOnlyList<UnifiedFieldDefinitionDto> FilterForMode(
            IReadOnlyList<UnifiedFieldDefinitionDto> fields,
            string entityName,
            EntityFormMode mode)
        {
            return fields
                .Where(f =>
                {
                    var template = EntityDefaultFieldTemplates.FindTemplate(entityName, f.FieldKey);
                    if (template == null)
                        return true;

                    if (mode == EntityFormMode.Create && template.HideInCreate)
                        return false;

                    return EntityDefaultFieldTemplates.ShouldIncludeInMode(template, mode);
                })
                .OrderBy(f => f.SortOrder)
                .ThenBy(f => f.DisplayName, StringComparer.OrdinalIgnoreCase)
                .ToList();
        }
    }
}
