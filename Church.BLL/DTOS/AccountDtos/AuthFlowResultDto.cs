namespace Church.BLL.DTOS.AccountDtos
{
    /// <summary>
    /// Login/register outcome — JWT on successful login, or registration-complete without token.
    /// </summary>
    public class AuthFlowResultDto
    {
        public string? Token { get; set; }
        public string? Message { get; set; }

        public static AuthFlowResultDto Success(string token) => new()
        {
            Token = token
        };

        public static AuthFlowResultDto Registered() => new();
    }
}
