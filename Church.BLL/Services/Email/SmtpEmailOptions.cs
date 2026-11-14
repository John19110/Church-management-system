namespace Church.BLL.Services.Email
{
    public sealed class SmtpEmailOptions
    {
        public const string SectionName = "Smtp";

        public string? Host { get; set; }

        public int Port { get; set; } = 587;

        public bool EnableSsl { get; set; } = true;

        public string? UserName { get; set; }

        public string? Password { get; set; }

        public string? FromAddress { get; set; }

        public string FromDisplayName { get; set; } = "My Church";

        public bool IsConfigured =>
            !string.IsNullOrWhiteSpace(Host) &&
            !string.IsNullOrWhiteSpace(FromAddress);
    }
}
