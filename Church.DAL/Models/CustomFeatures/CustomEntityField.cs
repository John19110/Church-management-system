namespace Church.DAL.Models.CustomFeatures
{
    public class CustomEntityField : ChurchEntity
    {
        public int Id { get; set; }
        public int EntityId { get; set; }
        public CustomEntity? Entity { get; set; }

        public string Name { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
        public CustomEntityFieldType FieldType { get; set; }

        public bool IsRequired { get; set; }
        public bool IsUnique { get; set; }
        public bool IsSearchable { get; set; }
        public bool ShowOnList { get; set; } = true;
        public bool ShowOnForm { get; set; } = true;
        public bool ShowOnDetails { get; set; } = true;
        public int DisplayOrder { get; set; }

        public string? Placeholder { get; set; }
        public string? ValidationRegex { get; set; }

        /// <summary>Target custom entity for EntityReference / EntityMultiReference.</summary>
        public int? TargetEntityId { get; set; }
        public CustomEntity? TargetEntity { get; set; }

        public CustomEntityCoreReference CoreReference { get; set; } = CustomEntityCoreReference.None;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
        public string? CreatedBy { get; set; }

        public ICollection<CustomEntityFieldOption> Options { get; set; } = new List<CustomEntityFieldOption>();
        public ICollection<CustomEntityRecordReference> References { get; set; } = new List<CustomEntityRecordReference>();
    }
}
