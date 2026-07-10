using Church.BLL.Abstractions;
using Church.BLL.Abstractions.Caching;
using Church.DAL.Abstractions;

namespace Church.API.Infrastructure.Caching
{
    /// <summary>
    /// Builds a CacheContext from the already-established request contexts:
    /// - TenantId from ITenantContext (ChurchId claim)
    /// - UserId + role from ICurrentUserContext
    /// </summary>
    public sealed class HttpCacheContextAccessor : ICacheContextAccessor
    {
        private static readonly string[] RolePriority =
        [
            "SuperAdmin",
            "Admin",
            "Pastor",
            "Secretary",
            "Servant",
            "Member"
        ];

        private readonly ITenantContext _tenant;
        private readonly ICurrentUserContext _currentUser;

        public HttpCacheContextAccessor(ITenantContext tenant, ICurrentUserContext currentUser)
        {
            _tenant = tenant;
            _currentUser = currentUser;
        }

        public CacheContext? TryGet()
        {
            var tenantId = _tenant.ChurchId;
            if (tenantId is null or <= 0)
                return null; // Never cache without a tenant id.

            var userId = _currentUser.UserId;
            var role = ResolvePrimaryRole();

            return new CacheContext(tenantId.Value, userId, role);
        }

        private string? ResolvePrimaryRole()
        {
            foreach (var role in RolePriority)
            {
                if (_currentUser.IsInRole(role))
                    return role;
            }

            // If roles are unknown, we still allow tenant-only caching for role-agnostic endpoints.
            return null;
        }
    }
}

