namespace SunDaySchools.DAL.Models.CustomFields
{
    /// <summary>
    /// EAV row storing one dynamic value. All payloads are persisted as string;
    /// parsing/validation happens in the service layer.
    /// </summary>
    public class CustomFieldValue
    {
        public int Id { get; set; }

        public int EntityId { get; set; }
        public string EntityName { get; set; } = string.Empty;

        public int CustomFieldDefinitionId { get; set; }
        public CustomFieldDefinition? Definition { get; set; }

        public string? Value { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
        public string? CreatedBy { get; set; }
    }
}
