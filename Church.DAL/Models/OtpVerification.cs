namespace Church.DAL.Models
{
    public class OtpVerification
    {
        public int Id { get; set; }
        public string PhoneNumber { get; set; } = string.Empty;
        /// <summary>Hashed OTP code (never store plain text in production DB).</summary>
        public string Code { get; set; } = string.Empty;
        public DateTime ExpirationTime { get; set; }
        public bool IsUsed { get; set; }
        public OtpPurpose Purpose { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public int FailedAttempts { get; set; }
    }
}
