using Church.BLL.Abstractions.Caching;

namespace Church.API.Infrastructure.Caching
{
    public static class CachingServiceCollectionExtensions
    {
        public static IServiceCollection AddTenantAwareCaching(this IServiceCollection services)
        {
            services.AddMemoryCache();

            services.AddScoped<ICacheContextAccessor, HttpCacheContextAccessor>();
            services.AddScoped<ICacheKeyBuilder, TenantAwareCacheKeyBuilder>();

            services.AddSingleton<ICacheService, MemoryCacheService>();

            return services;
        }
    }
}

