namespace Church.DAL.Models.CustomFields
{
    /// <summary>
    /// Select-list option for SingleSelect / MultiSelect fields.
    /// </summary>
    public class CustomFieldOption
    {
        public int Id { get; set; }
        public int CustomFieldDefinitionId { get; set; }
        public CustomFieldDefinition? Definition { get; set; }

        public string Value { get; set; } = string.Empty;
        public string DisplayText { get; set; } = string.Empty;
        public int SortOrder { get; set; }
    }
}
