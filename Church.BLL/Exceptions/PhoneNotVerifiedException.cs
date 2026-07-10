namespace Church.BLL.Exceptions
{
    public class PhoneNotVerifiedException : Exception
    {
        public string PhoneNumber { get; }

        public PhoneNotVerifiedException(string phoneNumber)
            : base("Phone number is not verified. Please complete WhatsApp OTP verification.")
        {
            PhoneNumber = phoneNumber;
        }
    }
}
