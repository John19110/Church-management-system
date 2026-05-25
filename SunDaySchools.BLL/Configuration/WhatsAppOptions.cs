namespace SunDaySchools.BLL.Configuration
{
    public class WhatsAppOptions
    {
        public const string SectionName = "WhatsApp";

        public bool Enabled { get; set; } = true;
        public string AccessToken { get; set; } = string.Empty;
        public string PhoneNumberId { get; set; } = string.Empty;
        public string ApiVersion { get; set; } = "v21.0";
        /// <summary>Display / business number (e.g. 01031177365).</summary>
        public string SenderDisplayNumber { get; set; } = "01031177365";
        public string DefaultCountryCode { get; set; } = "20";
    }
}
