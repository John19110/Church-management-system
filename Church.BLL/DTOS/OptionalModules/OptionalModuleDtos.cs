namespace Church.BLL.DTOS.OptionalModules
{
    public sealed class OptionalModuleReadDto
    {
        public string Id { get; set; } = string.Empty;
        public string NameEn { get; set; } = string.Empty;
        public string NameAr { get; set; } = string.Empty;
        public string DescriptionEn { get; set; } = string.Empty;
        public string DescriptionAr { get; set; } = string.Empty;
        public string Icon { get; set; } = string.Empty;
        public bool IsEnabled { get; set; }
    }

    public sealed class SetOptionalModuleEnabledDto
    {
        public bool IsEnabled { get; set; }
    }
}
