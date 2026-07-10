namespace Church.BLL.Exceptions
{
    public class OtpRateLimitException : Exception
    {
        public int RetryAfterSeconds { get; }

        public OtpRateLimitException(int retryAfterSeconds)
            : base($"Please wait {retryAfterSeconds} seconds before requesting another code.")
        {
            RetryAfterSeconds = retryAfterSeconds;
        }
    }
}
