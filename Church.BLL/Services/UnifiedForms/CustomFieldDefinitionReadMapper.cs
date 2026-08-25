using Church.BLL.DTOS.CustomFields;
using Church.DAL.Models.CustomFields;

namespace Church.BLL.Services.UnifiedForms
{
    /// <summary>
    /// Null-safe mapping for custom field definitions (avoids AutoMapper edge cases).
    /// </summary>
    public static class CustomFieldDefinitionReadMapper
    {
        public static CustomFieldDefinitionReadDto ToReadDto(CustomFieldDefinition def)
        {
            if (def == null)
            {
                return new CustomFieldDefinitionReadDto
                {
                    Name = string.Empty,
                    DisplayName = string.Empty,
                    EntityName = string.Empty,
                    Options = new List<CustomFieldOptionDto>()
                };
            }

            var isBuiltIn = EntityDefaultFieldTemplates.IsBuiltInField(def.EntityName, def.Name);

            return new CustomFieldDefinitionReadDto
            {
                Id = def.Id,
                Name = def.Name ?? string.Empty,
                DisplayName = def.DisplayName ?? string.Empty,
                DisplayNameAr = def.DisplayNameAr,
                Description = def.Description,
                EntityName = def.EntityName ?? string.Empty,
                DataType = def.DataType,
                IsRequired = def.IsRequired,
                IsActive = def.IsActive,
                IsReadOnly = def.IsReadOnly,
                IsHidden = def.IsHidden,
                AllowMultipleValues = def.AllowMultipleValues,
                DefaultValue = def.DefaultValue,
                Placeholder = def.Placeholder,
                ValidationRegex = def.ValidationRegex,
                SortOrder = def.SortOrder,
                CreatedAt = def.CreatedAt,
                UpdatedAt = def.UpdatedAt,
                IsBuiltIn = isBuiltIn,
                IsSystemField = isBuiltIn,
                IsDeletable = !EntityDefaultFieldTemplates.IsCriticalField(def.EntityName, def.Name),
                IsPermanentDeletable =
                    !EntityDefaultFieldTemplates.IsCriticalField(def.EntityName, def.Name),
                Options = (def.Options ?? Array.Empty<CustomFieldOption>())
                    .Where(o => o != null)
                    .OrderBy(o => o.SortOrder)
                    .Select(o => new CustomFieldOptionDto
                    {
                        Id = o.Id,
                        Value = o.Value ?? string.Empty,
                        DisplayText = o.DisplayText ?? string.Empty,
                        SortOrder = o.SortOrder
                    })
                    .ToList()
            };
        }

        public static List<CustomFieldDefinitionReadDto> ToReadDtoList(
            IEnumerable<CustomFieldDefinition>? definitions) =>
            (definitions ?? Array.Empty<CustomFieldDefinition>())
                .Where(d => d != null)
                .Select(ToReadDto)
                .ToList();

        public static EntityFieldDefinitionDto ToFieldDefinitionSummary(CustomFieldDefinitionReadDto def) =>
            new()
            {
                Id = def.Id,
                Name = def.Name,
                DisplayName = def.DisplayName,
                DisplayNameAr = def.DisplayNameAr,
                Type = def.DataType.ToString(),
                Required = def.IsRequired,
                IsSystemField = def.IsSystemField,
                IsReadOnly = def.IsReadOnly,
                IsHidden = def.IsHidden,
                SortOrder = def.SortOrder,
            };
    }
}
