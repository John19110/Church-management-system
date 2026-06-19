using SunDaySchools.DAL.Models;

namespace SunDaySchools.DAL.Models.CustomFields
{
    /// <summary>
    /// Metadata for a tenant-scoped dynamic field. Values live in <see cref="CustomFieldValue"/>.
    /// Inherits ChurchEntity so global query filters apply automatically.
    /// </summary>
    public class CustomFieldDefinition : ChurchEntity
    {
        public int Id { get; set; }

        /// <summary>Internal stable key (unique per entity + tenant).</summary>
        public string Name { get; set; } = string.Empty;

        public string DisplayName { get; set; } = string.Empty;

        /// <summary>Arabic display label shown when the UI locale is Arabic.</summary>
        public string? DisplayNameAr { get; set; }

        public string? Description { get; set; }

        /// <summary>Target entity: Member, Classroom, Servant, Meeting.</summary>
        public string EntityName { get; set; } = string.Empty;

        public CustomFieldDataType DataType { get; set; }

        public bool IsRequired { get; set; }
        public bool IsActive { get; set; } = true;

        /// <summary>When true the field was permanently removed and must not be re-provisioned or shown.</summary>
        public bool IsPermanentlyDeleted { get; set; }

        public bool IsReadOnly { get; set; }
        public bool IsHidden { get; set; }
        public bool AllowMultipleValues { get; set; }

        public string? DefaultValue { get; set; }
        public string? Placeholder { get; set; }
        public string? ValidationRegex { get; set; }
        public int SortOrder { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
        public string? CreatedBy { get; set; }

        public ICollection<CustomFieldOption> Options { get; set; } = new List<CustomFieldOption>();
        public ICollection<CustomFieldValue> Values { get; set; } = new List<CustomFieldValue>();
    }
}
