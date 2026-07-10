namespace Church.BLL.Abstractions.Caching
{
    /// <summary>
    /// Centralizes tenant/role/user safe cache key generation.
    /// </summary>
    public interface ICacheKeyBuilder
    {
        string Tenant(string segment);
        string TenantRole(string role, string segment);
        string TenantUser(string userId, string segment);

        string TenantRole(string role, string segment, params (string Name, object? Value)[] parts);
        string Tenant(string segment, params (string Name, object? Value)[] parts);
        string TenantUser(string userId, string segment, params (string Name, object? Value)[] parts);
    }
}

