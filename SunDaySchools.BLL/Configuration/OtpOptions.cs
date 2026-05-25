namespace SunDaySchools.BLL.Configuration
{
    public class OtpOptions
    {
        public const string SectionName = "Otp";

        public int CodeLength { get; set; } = 6;
        public int ExpirationMinutes { get; set; } = 5;
        public int ResendCooldownSeconds { get; set; } = 60;
        public int MaxSendsPerWindow { get; set; } = 5;
        public int SendWindowMinutes { get; set; } = 15;
        public int MaxVerifyAttemptsPerOtp { get; set; } = 5;
        public string HashSecret { get; set; } = "ChangeMe-Otp-Secret-In-Production";
    }
}
