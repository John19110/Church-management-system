namespace Church.BLL.DTOS.AccountDtos
{
    public class LanguageProfileDto
    {
        public string? PreferredLanguage { get; set; }
        public IReadOnlyList<string> SupportedLanguages { get; set; } = Array.Empty<string>();
        public string DefaultLanguage { get; set; } = "en";
    }

    public class UpdatePreferredLanguageDto
    {
        public string PreferredLanguage { get; set; } = "en";
    }
}
