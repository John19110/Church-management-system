using Microsoft.AspNetCore.Mvc;
using Church.BLL.DTOS.AccountDtos;

namespace Church.API.Controllers
{
    internal static class AuthResponseHelper
    {
        public static ActionResult ToActionResult(this AuthFlowResultDto result)
        {
            if (result.RequiresPhoneVerification)
            {
                return new OkObjectResult(new
                {
                    requiresPhoneVerification = true,
                    phoneNumber = result.PhoneNumber,
                    message = result.Message
                });
            }

            return new OkObjectResult(new { token = result.Token });
        }
    }
}
