using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using SunDaySchools.BLL.Abstractions;

namespace SunDaySchools.API.Infrastructure.Tenant
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
            Principal?.IsInRole(role) == true;

        public string? GetClaim(string claimType) =>
            Principal?.FindFirstValue(claimType);
    }
}
