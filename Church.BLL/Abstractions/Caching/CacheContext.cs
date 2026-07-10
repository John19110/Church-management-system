namespace Church.BLL.Abstractions.Caching
{
    /// <summary>
    /// Context used to build safe cache keys and produce audit-friendly logs.
    /// TenantId is required for all caching to prevent cross-tenant leakage.
    /// </summary>
    public sealed record CacheContext(
        int TenantId,
        string? UserId,
        string? Role);
}

