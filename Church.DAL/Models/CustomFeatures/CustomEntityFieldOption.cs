namespace Church.DAL.Models.CustomFeatures
{
    public class CustomEntityFieldOption
    {
        public int Id { get; set; }
        public int FieldId { get; set; }
        public CustomEntityField? Field { get; set; }

        public string Value { get; set; } = string.Empty;
        public string DisplayText { get; set; } = string.Empty;
        public string? DisplayTextAr { get; set; }
        public int SortOrder { get; set; }
    }
}
