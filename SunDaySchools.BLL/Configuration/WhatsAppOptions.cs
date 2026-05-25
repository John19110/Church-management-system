namespace SunDaySchools.BLL.Configuration
{
    public class WhatsAppOptions
    {
        public const string SectionName = "WhatsApp";

        public bool Enabled { get; set; } = true;
        public string AccessToken { get; set; } = string.Empty;
        public string PhoneNumberId { get; set; } = string.Empty;
        public string ApiVersion { get; set; } = "v21.0";
        /// <summary>Meta WhatsApp business display number (e.g. +1 555 654 1489).</summary>
        public string SenderDisplayNumber { get; set; } = "+15556541489";
        public string DefaultCountryCode { get; set; } = "20";
    }
}
