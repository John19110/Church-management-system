namespace Church.BLL.DTOS.AccountDtos
{
    /// <summary>
    /// Login/register outcome. Approved login or approved new-church registration
    /// returns a JWT; pending join registration returns no token.
    /// </summary>
    public class AuthFlowResultDto
    {
        public string? Token { get; set; }
        public string? Message { get; set; }

        public static AuthFlowResultDto Success(string token) => new()
        {
            Token = token
        };

        /// <summary>Registration completed without issuing a session (e.g. pending approval).</summary>
        public static AuthFlowResultDto Registered() => new();
    }
}
