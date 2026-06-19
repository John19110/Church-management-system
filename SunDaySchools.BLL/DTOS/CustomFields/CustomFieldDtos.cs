using SunDaySchools.DAL.Models.CustomFields;

namespace SunDaySchools.BLL.DTOS.CustomFields
{
    public class CustomFieldOptionDto
    {
        public int? Id { get; set; }
        public string Value { get; set; } = string.Empty;
        public string DisplayText { get; set; } = string.Empty;
        public int SortOrder { get; set; }
    }

    public class CustomFieldDefinitionReadDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
        public string? Description { get; set; }
        public string EntityName { get; set; } = string.Empty;
        public CustomFieldDataType DataType { get; set; }
        public bool IsRequired { get; set; }
        public bool IsActive { get; set; }
        public bool IsReadOnly { get; set; }
        public bool IsHidden { get; set; }
        public bool AllowMultipleValues { get; set; }
        public string? DefaultValue { get; set; }
        public string? Placeholder { get; set; }
        public string? ValidationRegex { get; set; }
        public int SortOrder { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public List<CustomFieldOptionDto> Options { get; set; } = new();

        /// <summary>True when the field maps to a built-in model property.</summary>
        public bool IsBuiltIn { get; set; }

        /// <summary>Alias for <see cref="IsBuiltIn"/> in field-definitions API responses.</summary>
        public bool IsSystemField { get; set; }

        /// <summary>False for critical system fields that cannot be deactivated.</summary>
        public bool IsDeletable { get; set; } = true;

        /// <summary>False for built-in/system fields; permanent delete applies to user-created fields only.</summary>
        public bool IsPermanentDeletable { get; set; } = true;
    }

    /// <summary>Lightweight field metadata for field-definitions endpoints.</summary>
    public class EntityFieldDefinitionDto
    {
        public string Name { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty;
        public bool Required { get; set; }
        public bool IsSystemField { get; set; }
        public bool IsReadOnly { get; set; }
        public bool IsHidden { get; set; }
        public int SortOrder { get; set; }
        public int? Id { get; set; }
    }

    public class CustomFieldDefinitionCreateDto
    {
        public string Name { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
        public string? Description { get; set; }
        public string EntityName { get; set; } = string.Empty;
        public CustomFieldDataType DataType { get; set; }
        public bool IsRequired { get; set; }
        public bool IsReadOnly { get; set; }
        public bool IsHidden { get; set; }
        public bool AllowMultipleValues { get; set; }
        public string? DefaultValue { get; set; }
        public string? Placeholder { get; set; }
        public string? ValidationRegex { get; set; }
        public int SortOrder { get; set; }
        public List<CustomFieldOptionDto>? Options { get; set; }

        /// <summary>1-based appearance position among active fields. When set, overrides <see cref="SortOrder"/>.</summary>
        public int? DisplayPosition { get; set; }
    }

    public class CustomFieldDefinitionUpdateDto
    {
        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
        public string? Description { get; set; }
        public CustomFieldDataType? DataType { get; set; }
        public bool? IsRequired { get; set; }
        public bool? IsActive { get; set; }
        public bool? IsReadOnly { get; set; }
        public bool? IsHidden { get; set; }
        public bool? AllowMultipleValues { get; set; }
        public string? DefaultValue { get; set; }
        public string? Placeholder { get; set; }
        public string? ValidationRegex { get; set; }
        public int? SortOrder { get; set; }
        public List<CustomFieldOptionDto>? Options { get; set; }

        /// <summary>1-based appearance position among active fields. When set, overrides <see cref="SortOrder"/>.</summary>
        public int? DisplayPosition { get; set; }
    }

    public class CustomFieldValueItemDto
    {
        public int CustomFieldDefinitionId { get; set; }
        public string? Value { get; set; }
    }

    public class CustomFieldValueReadDto
    {
        public int CustomFieldDefinitionId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public CustomFieldDataType DataType { get; set; }
        public string? Value { get; set; }
        public bool IsReadOnly { get; set; }
        public bool IsHidden { get; set; }
    }

    public class SaveCustomFieldValuesDto
    {
        public string EntityName { get; set; } = string.Empty;
        public int EntityId { get; set; }
        public List<CustomFieldValueItemDto> Values { get; set; } = new();
    }

    public class EntityCustomFieldsReadDto
    {
        public string EntityName { get; set; } = string.Empty;
        public int EntityId { get; set; }
        public List<CustomFieldDefinitionReadDto> Definitions { get; set; } = new();
        public List<CustomFieldValueReadDto> Values { get; set; } = new();
    }

    public class CustomFieldTypeChangeCheckDto
    {
        public bool CanChange { get; set; }
        public int ExistingValueCount { get; set; }
        public int InvalidValueCount { get; set; }
        public List<string> SampleInvalidValues { get; set; } = new();
        public string? Message { get; set; }
    }
}
