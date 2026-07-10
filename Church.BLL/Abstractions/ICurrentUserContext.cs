namespace Church.BLL.Abstractions
{
    /// <summary>
    /// Authenticated user identity for the current request (no HttpContext in BLL).
    /// </summary>
    public interface ICurrentUserContext
    {
        bool IsAuthenticated { get; }
        string? UserId { get; }
        bool IsInRole(string role);
        string? GetClaim(string claimType);
    }
}
