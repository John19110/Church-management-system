using System.Text;
using Church.BLL.Abstractions.Caching;

namespace Church.API.Infrastructure.Caching
{
    /// <summary>
    /// Cache key builder that enforces tenant isolation and supports role/user scoping.
    /// Keys are string-only so they map directly to Redis later.
    /// </summary>
    public sealed class TenantAwareCacheKeyBuilder : ICacheKeyBuilder
    {
        private readonly ICacheContextAccessor _contextAccessor;

        public TenantAwareCacheKeyBuilder(ICacheContextAccessor contextAccessor)
        {
            _contextAccessor = contextAccessor;
        }

        public string Tenant(string segment) =>
            Build(segment, role: null, userId: null);

        public string Tenant(string segment, params (string Name, object? Value)[] parts) =>
            Build(segment, role: null, userId: null, parts: parts);

        public string TenantRole(string role, string segment) =>
            Build(segment, role: role, userId: null);

        public string TenantRole(string role, string segment, params (string Name, object? Value)[] parts) =>
            Build(segment, role: role, userId: null, parts: parts);

        public string TenantUser(string userId, string segment) =>
            Build(segment, role: null, userId: userId);

        public string TenantUser(string userId, string segment, params (string Name, object? Value)[] parts) =>
            Build(segment, role: null, userId: userId, parts: parts);

        private string Build(
            string segment,
            string? role,
            string? userId,
            params (string Name, object? Value)[] parts)
        {
            var ctx = _contextAccessor.TryGet()
                ?? throw new InvalidOperationException(
                    "TenantId is missing for the current request. Caching is disabled for safety.");

            var sb = new StringBuilder();
            sb.Append("tenant:").Append(ctx.TenantId);

            if (!string.IsNullOrWhiteSpace(role))
            {
                sb.Append(":role:").Append(role);
            }

            if (!string.IsNullOrWhiteSpace(userId))
            {
                sb.Append(":user:").Append(userId);
            }

            sb.Append(':').Append(segment);

            if (parts is { Length: > 0 })
            {
                foreach (var (name, value) in parts)
                {
                    sb.Append(':').Append(name).Append('=').Append(value ?? "null");
                }
            }

            return sb.ToString();
        }
    }
}

