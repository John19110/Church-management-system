using Microsoft.AspNetCore.Mvc;
using Church.BLL.DTOS.AccountDtos;

namespace Church.API.Controllers
{
    internal static class AuthResponseHelper
    {
        public static ActionResult ToActionResult(this AuthFlowResultDto result)
        {
            if (!string.IsNullOrEmpty(result.Token))
            {
                return new OkObjectResult(new { token = result.Token });
            }

            // Registration complete — no phone-verification payload.
            return new OkObjectResult(new { registered = true });
        }
    }
}
