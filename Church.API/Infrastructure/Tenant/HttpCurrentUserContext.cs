using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Church.BLL.Abstractions;

namespace Church.API.Infrastructure.Tenant
{
    public sealed class HttpCurrentUserContext : ICurrentUserContext
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public HttpCurrentUserContext(IHttpContextAccessor httpContextAccessor)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        private ClaimsPrincipal? Principal =>
            _httpContextAccessor.HttpContext?.User;

        public bool IsAuthenticated =>
            Principal?.Identity?.IsAuthenticated == true;

        public string? UserId =>
            Principal?.FindFirstValue(JwtRegisteredClaimNames.Sub)
            ?? Principal?.FindFirstValue(ClaimTypes.NameIdentifier);

        public bool IsInRole(string role) =>
            Principal?.IsInRole(role) == true
            || Principal?.Claims.Any(c =>
                IsRoleClaimType(c.Type)
                && string.Equals(c.Value, role, StringComparison.OrdinalIgnoreCase)) == true;

        private static bool IsRoleClaimType(string claimType) =>
            string.Equals(claimType, ClaimTypes.Role, StringComparison.OrdinalIgnoreCase)
            || string.Equals(claimType, "role", StringComparison.OrdinalIgnoreCase)
            || string.Equals(claimType, "roles", StringComparison.OrdinalIgnoreCase)
            || claimType.EndsWith("/role", StringComparison.OrdinalIgnoreCase);

        public string? GetClaim(string claimType) =>
            Principal?.FindFirstValue(claimType);
    }
}
