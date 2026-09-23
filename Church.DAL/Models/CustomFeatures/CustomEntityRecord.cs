namespace Church.DAL.Models.CustomFeatures
{
    public class CustomEntityRecord : ChurchEntity
    {
        public int Id { get; set; }
        public int EntityId { get; set; }
        public CustomEntity? Entity { get; set; }

        public string DataJson { get; set; } = "{}";

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
        public string? CreatedBy { get; set; }

        public ICollection<CustomEntityRecordReference> References { get; set; } = new List<CustomEntityRecordReference>();
    }
}
