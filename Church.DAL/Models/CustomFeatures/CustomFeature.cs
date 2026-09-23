namespace Church.DAL.Models.CustomFeatures
{
    /// <summary>
    /// Church-owned configurable mini-domain. Church-wide when MeetingId is null.
    /// </summary>
    public class CustomFeature : ChurchEntity
    {
        public int Id { get; set; }

        /// <summary>Internal stable key (unique per church + meeting scope).</summary>
        public string Name { get; set; } = string.Empty;

        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
        public string? CreatedBy { get; set; }

        public ICollection<CustomEntity> Entities { get; set; } = new List<CustomEntity>();
    }
}
