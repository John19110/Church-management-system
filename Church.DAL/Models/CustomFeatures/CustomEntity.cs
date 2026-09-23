namespace Church.DAL.Models.CustomFeatures
{
    public class CustomEntity : ChurchEntity
    {
        public int Id { get; set; }
        public int FeatureId { get; set; }
        public CustomFeature? Feature { get; set; }

        public string Name { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
        public string PluralDisplayName { get; set; } = string.Empty;
        public string? PluralDisplayNameAr { get; set; }
        public bool IsActive { get; set; } = true;
        public int SortOrder { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
        public string? CreatedBy { get; set; }

        public ICollection<CustomEntityField> Fields { get; set; } = new List<CustomEntityField>();
        public ICollection<CustomEntityPermission> Permissions { get; set; } = new List<CustomEntityPermission>();
        public ICollection<CustomEntityRecord> Records { get; set; } = new List<CustomEntityRecord>();
    }
}
