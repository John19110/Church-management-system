using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;

namespace Church.API.Infrastructure.DependencyInjection
{
    public static class RateLimitingServiceCollectionExtensions
    {
        public static IServiceCollection AddRateLimitingServices(this IServiceCollection services)
        {
            // Auth endpoints are otherwise an unmetered password-guessing oracle.
            // Partition key is remote IP; reverse proxies should forward the real client IP
            // (or this collapses to the proxy address and becomes shared).
            services.AddRateLimiter(options =>
            {
                options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

                options.AddPolicy("auth", context => RateLimitPartition.GetFixedWindowLimiter(

                    //Create a separate rate-limit bucket for each IP address.
                    partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
                    factory: _ => new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = 10,

                        Window = TimeSpan.FromMinutes(1),


                        //the 11th is regected 
                        QueueLimit = 0
                    }));

                options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
                    RateLimitPartition.GetFixedWindowLimiter(
                       
                        partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
                        
                        factory: _ => new FixedWindowRateLimiterOptions
                        {
                            PermitLimit = 300,
                            Window = TimeSpan.FromMinutes(1),
                            QueueLimit = 0
                        }));
            });

            return services;
        }
    }
}
