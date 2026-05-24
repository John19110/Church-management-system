using SunDaySchools.DAL.Models.CustomFields;

namespace SunDaySchools.BLL.DTOS.UnifiedForms
{
    /// <summary>
    /// Single field descriptor used for both built-in and custom dynamic fields.
    /// </summary>
    public class UnifiedFieldDefinitionDto
    {
        public string FieldKey { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string? Description { get; set; }
        public CustomFieldDataType DataType { get; set; }
        public bool IsRequired { get; set; }
        public bool IsBuiltIn { get; set; }
        public bool IsReadOnly { get; set; }
        public bool IsHidden { get; set; }
        public int SortOrder { get; set; }
        public bool AllowMultipleValues { get; set; }
        public string? DefaultValue { get; set; }
        public string? Placeholder { get; set; }
        public string? ValidationRegex { get; set; }
        public List<UnifiedFieldOptionDto> Options { get; set; } = new();

        /// <summary>For SingleSelect fields loaded from an API (e.g. /api/Classroom/select).</summary>
        public string? LookupEndpoint { get; set; }

        /// <summary>Set only for custom fields; used when persisting values.</summary>
        public int? CustomFieldDefinitionId { get; set; }
    }

    public class UnifiedFieldOptionDto
    {
        public string Value { get; set; } = string.Empty;
        public string DisplayText { get; set; } = string.Empty;
        public int SortOrder { get; set; }
    }

    /// <summary>Definition plus current value (form render / detail).</summary>
    public class UnifiedFieldDto : UnifiedFieldDefinitionDto
    {
        public string? Value { get; set; }
    }

    public class EntityFormSchemaDto
    {
        public string EntityName { get; set; } = string.Empty;
        public string FormMode { get; set; } = "Edit";
        public List<UnifiedFieldDefinitionDto> Fields { get; set; } = new();
    }

    public class EntityFormDataDto
    {
        public string EntityName { get; set; } = string.Empty;
        public int EntityId { get; set; }
        public List<UnifiedFieldDto> Fields { get; set; } = new();
    }

    public class SaveEntityFormDto
    {
        public List<UnifiedFieldValueDto> Fields { get; set; } = new();
    }

    public class UnifiedFieldValueDto
    {
        public string FieldKey { get; set; } = string.Empty;
        public string? Value { get; set; }
    }
}
