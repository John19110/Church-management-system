using Microsoft.AspNetCore.Mvc;
using Church.BLL.DTOS.AccountDtos;
using Church.BLL.Services.Auth.Interfaces;

namespace Church.API.Controllers
{
    [ApiController]
    [Route("api/auth")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthOtpManager _authOtpManager;

        public AuthController(IAuthOtpManager authOtpManager)
        {
            _authOtpManager = authOtpManager;
        }

        [HttpPost("send-whatsapp-otp")]
        public async Task<ActionResult<OtpOperationResultDto>> SendWhatsAppOtp(
            [FromBody] SendWhatsAppOtpDto dto)
        {
            var result = await _authOtpManager.SendPhoneVerificationOtpAsync(dto.PhoneNumber);
            return Ok(result);
        }

        [HttpPost("verify-whatsapp-otp")]
        public async Task<ActionResult<OtpOperationResultDto>> VerifyWhatsAppOtp(
            [FromBody] VerifyWhatsAppOtpDto dto)
        {
            var result = await _authOtpManager.VerifyPhoneVerificationOtpAsync(
                dto.PhoneNumber,
                dto.Code);
            return Ok(result);
        }

        [HttpPost("forgot-password")]
        public async Task<ActionResult<OtpOperationResultDto>> ForgotPassword(
            [FromBody] ForgotPasswordDto dto)
        {
            var result = await _authOtpManager.SendPasswordResetOtpAsync(dto.PhoneNumber);
            return Ok(result);
        }

        [HttpPost("reset-password")]
        public async Task<ActionResult<OtpOperationResultDto>> ResetPassword(
            [FromBody] ResetPasswordDto dto)
        {
            var result = await _authOtpManager.ResetPasswordAsync(dto);
            return Ok(result);
        }
    }
}
