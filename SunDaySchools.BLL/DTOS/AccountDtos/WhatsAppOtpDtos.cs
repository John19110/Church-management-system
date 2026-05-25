using System.ComponentModel.DataAnnotations;

namespace SunDaySchools.BLL.DTOS.AccountDtos
{
    public class SendWhatsAppOtpDto
    {
        [Required]
        public string PhoneNumber { get; set; } = string.Empty;
    }

    public class VerifyWhatsAppOtpDto
    {
        [Required]
        public string PhoneNumber { get; set; } = string.Empty;

        [Required]
        [StringLength(6, MinimumLength = 6)]
        public string Code { get; set; } = string.Empty;
    }

    public class ForgotPasswordDto
    {
        [Required]
        public string PhoneNumber { get; set; } = string.Empty;
    }

    public class ResetPasswordDto
    {
        [Required]
        public string PhoneNumber { get; set; } = string.Empty;

        [Required]
        [StringLength(6, MinimumLength = 6)]
        public string Code { get; set; } = string.Empty;

        [Required]
        [MinLength(6)]
        public string NewPassword { get; set; } = string.Empty;
    }

    public class OtpOperationResultDto
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public int? ResendCooldownSeconds { get; set; }
    }
}
