namespace Church.BLL.Abstractions
{
    public sealed class TokenClaimDescriptor
    {
        public string Type { get; init; } = string.Empty;
        public string Value { get; init; } = string.Empty;
    }

    /// <summary>
    /// Creates access tokens. Implementation lives in API (JWT framework details).
    /// </summary>
    public interface ITokenService
    {
        string CreateAccessToken(
            IReadOnlyList<TokenClaimDescriptor> claims,
            TimeSpan? lifetime = null);
    }
}
