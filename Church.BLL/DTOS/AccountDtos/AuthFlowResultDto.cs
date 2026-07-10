namespace Church.BLL.DTOS.AccountDtos
{
    /// <summary>
    /// Login/register outcome — preserves JWT when allowed, or signals phone verification required.
    /// </summary>
    public class AuthFlowResultDto
    {
        public string? Token { get; set; }
        public bool RequiresPhoneVerification { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Message { get; set; }

        public static AuthFlowResultDto Success(string token) => new()
        {
            Token = token,
            RequiresPhoneVerification = false
        };

        public static AuthFlowResultDto RequiresVerification(string phoneNumber) => new()
        {
            RequiresPhoneVerification = true,
            PhoneNumber = phoneNumber,
            Message = "Please verify your phone number with the WhatsApp code we sent."
        };
    }
}
