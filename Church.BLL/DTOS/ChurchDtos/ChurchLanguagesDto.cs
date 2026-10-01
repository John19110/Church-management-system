namespace Church.BLL.DTOS.ChurchDtos
{
    public class ChurchLanguagesDto
    {
        public IReadOnlyList<string> SupportedLanguages { get; set; } = Array.Empty<string>();
        public string DefaultLanguage { get; set; } = "en";
        public bool IsCustomizationLanguagesConfigured { get; set; }
    }

    public class ChurchLanguagesUpdateDto
    {
        public IReadOnlyList<string> SupportedLanguages { get; set; } = Array.Empty<string>();
        public string DefaultLanguage { get; set; } = "en";
    }
}
