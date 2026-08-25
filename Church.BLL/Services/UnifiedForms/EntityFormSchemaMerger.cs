using Church.BLL.DTOS.UnifiedForms;

namespace Church.BLL.Services.UnifiedForms
{
    /// <summary>
    /// Enriches admin-configured definitions with built-in metadata (isBuiltIn, lookup endpoints).
    /// </summary>
    public static class EntityFormSchemaMerger
    {
        public static IReadOnlyList<UnifiedFieldDefinitionDto> MergeWithTemplates(
            IReadOnlyList<UnifiedFieldDefinitionDto> fromDb,
            string entityName,
            EntityFormMode mode,
            IReadOnlySet<string>? suppressedTemplateKeys = null)
        {
            var byKey = fromDb.ToDictionary(f => f.FieldKey, StringComparer.OrdinalIgnoreCase);
            var merged = new List<UnifiedFieldDefinitionDto>();

            foreach (var template in EntityDefaultFieldTemplates.GetTemplates(entityName))
            {
                if (byKey.TryGetValue(template.Name, out var existing))
                {
                    merged.Add(EnrichFromTemplate(existing, template));
                    byKey.Remove(template.Name);
                }
                else if (EntityDefaultFieldTemplates.ShouldIncludeInMode(template, mode)
                         && suppressedTemplateKeys?.Contains(template.Name) != true)
                {
                    merged.Add(TemplateToUnifiedField(template));
                }
            }

            merged.AddRange(byKey.Values.OrderBy(f => f.SortOrder));
            return merged
                .OrderBy(f => f.SortOrder)
                .ThenBy(f => f.DisplayName, StringComparer.OrdinalIgnoreCase)
                .ToList();
        }

        private static UnifiedFieldDefinitionDto EnrichFromTemplate(
            UnifiedFieldDefinitionDto field,
            EntityDefaultFieldTemplates.Template template)
        {
            field.IsBuiltIn = true;
            if (string.IsNullOrWhiteSpace(field.LookupEndpoint))
                field.LookupEndpoint = template.LookupEndpoint;
            return field;
        }

        private static UnifiedFieldDefinitionDto TemplateToUnifiedField(
            EntityDefaultFieldTemplates.Template template) =>
            new()
            {
                FieldKey = template.Name,
                DisplayName = template.DisplayName,
                DisplayNameAr = null,
                DataType = template.DataType,
                IsRequired = template.IsRequired,
                IsBuiltIn = true,
                IsReadOnly = template.IsReadOnly,
                IsHidden = template.IsHidden,
                SortOrder = template.SortOrder,
                Placeholder = template.Placeholder,
                ValidationRegex = template.ValidationRegex,
                LookupEndpoint = template.LookupEndpoint,
            };
    }
}
