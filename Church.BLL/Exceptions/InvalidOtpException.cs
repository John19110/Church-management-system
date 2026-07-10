namespace Church.BLL.Exceptions
{
    public class InvalidOtpException : Exception
    {
        public InvalidOtpException()
            : base("Invalid or expired verification code.") { }

        public InvalidOtpException(string message) : base(message) { }
    }
}
