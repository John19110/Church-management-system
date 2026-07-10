using System.Diagnostics.CodeAnalysis;

namespace Church.BLL.Abstractions.Caching
{
    /// <summary>
    /// Reusable caching abstraction. Business logic depends on this interface only.
    /// Swap implementation to Redis later without changing BLL code.
    /// </summary>
    public interface ICacheService
    {
        ValueTask<(bool Found, T? Value)> TryGetAsync<T>(
            string key,
            CacheContext context,
            CancellationToken ct = default);

        ValueTask SetAsync<T>(
            string key,
            T value,
            CacheEntryOptions options,
            CacheContext context,
            CancellationToken ct = default);

        /// <summary>
        /// Ensures only one concurrent factory populates a missing/expired entry (stampede protection).
        /// </summary>
        ValueTask<T> GetOrCreateAsync<T>(
            string key,
            CacheEntryOptions options,
            CacheContext context,
            Func<CancellationToken, Task<T>> factory,
            CancellationToken ct = default);

        ValueTask RemoveAsync(
            string key,
            CacheContext context,
            CancellationToken ct = default);

        /// <summary>
        /// Removes cached entries for the current tenant that relate to a logical segment (e.g. "events", "dashboard").
        /// This is implemented efficiently per-cache backend (IMemoryCache now, Redis later).
        /// </summary>
        ValueTask RemoveTenantSegmentAsync(
            string segment,
            CacheContext context,
            CancellationToken ct = default);
    }
}

