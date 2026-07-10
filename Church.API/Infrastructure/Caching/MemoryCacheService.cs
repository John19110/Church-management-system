using System.Collections.Concurrent;
using Microsoft.Extensions.Caching.Memory;
using Church.BLL.Abstractions.Caching;

namespace Church.API.Infrastructure.Caching
{
    /// <summary>
    /// IMemoryCache-based implementation. Swappable with Redis/IDistributedCache later.
    /// Includes stampede protection (single flight per key) and structured logging.
    /// </summary>
    public sealed class MemoryCacheService : ICacheService
    {
        private readonly IMemoryCache _cache;
        private readonly ILogger<MemoryCacheService> _logger;
        private readonly ConcurrentDictionary<string, SemaphoreSlim> _keyLocks = new();
        private readonly ConcurrentDictionary<int, ConcurrentDictionary<string, byte>> _tenantKeys = new();

        public MemoryCacheService(IMemoryCache cache, ILogger<MemoryCacheService> logger)
        {
            _cache = cache;
            _logger = logger;
        }

        public ValueTask<(bool Found, T? Value)> TryGetAsync<T>(
            string key,
            CacheContext context,
            CancellationToken ct = default)
        {
            if (_cache.TryGetValue(key, out var obj) && obj is T value)
            {
                Log(CacheEventType.Hit, key, context);
                return ValueTask.FromResult((true, value));
            }

            Log(CacheEventType.Miss, key, context);
            return ValueTask.FromResult((false, default(T)));
        }

        public ValueTask SetAsync<T>(
            string key,
            T value,
            CacheEntryOptions options,
            CacheContext context,
            CancellationToken ct = default)
        {
            _cache.Set(key, value!, new MemoryCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = options.AbsoluteExpirationRelativeToNow
            });

            var keys = _tenantKeys.GetOrAdd(context.TenantId, static _ => new ConcurrentDictionary<string, byte>());
            keys[key] = 0;

            Log(CacheEventType.Refresh, key, context);
            return ValueTask.CompletedTask;
        }

        public async ValueTask<T> GetOrCreateAsync<T>(
            string key,
            CacheEntryOptions options,
            CacheContext context,
            Func<CancellationToken, Task<T>> factory,
            CancellationToken ct = default)
        {
            // Fast path.
            var (found, value) = await TryGetAsync<T>(key, context, ct);
            if (found)
                return value!;

            var gate = _keyLocks.GetOrAdd(key, static _ => new SemaphoreSlim(1, 1));
            await gate.WaitAsync(ct);
            try
            {
                // Re-check once inside the lock.
                var (found2, value2) = await TryGetAsync<T>(key, context, ct);
                if (found2)
                    return value2!;

                var created = await factory(ct);
                await SetAsync(key, created, options, context, ct);
                return created;
            }
            finally
            {
                gate.Release();
            }
        }

        public ValueTask RemoveAsync(
            string key,
            CacheContext context,
            CancellationToken ct = default)
        {
            _cache.Remove(key);
            if (_tenantKeys.TryGetValue(context.TenantId, out var keys))
                keys.TryRemove(key, out _);
            Log(CacheEventType.Remove, key, context);
            return ValueTask.CompletedTask;
        }

        public ValueTask RemoveTenantSegmentAsync(
            string segment,
            CacheContext context,
            CancellationToken ct = default)
        {
            if (!_tenantKeys.TryGetValue(context.TenantId, out var keys) || keys.IsEmpty)
                return ValueTask.CompletedTask;

            var needle = ":" + segment;

            foreach (var k in keys.Keys)
            {
                if (!k.Contains(needle, StringComparison.OrdinalIgnoreCase))
                    continue;

                _cache.Remove(k);
                keys.TryRemove(k, out _);
                Log(CacheEventType.Remove, k, context);
            }

            return ValueTask.CompletedTask;
        }

        private void Log(CacheEventType type, string key, CacheContext context)
        {
            _logger.LogInformation(
                "Cache {CacheEvent} TenantId={TenantId} UserId={UserId} Role={Role} Key={CacheKey}",
                type.ToString(),
                context.TenantId,
                context.UserId ?? string.Empty,
                context.Role ?? string.Empty,
                key);
        }
    }
}

