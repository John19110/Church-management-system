using Church.API.Authorization;
using Microsoft.AspNetCore.Authorization;

namespace Church.API.Infrastructure.DependencyInjection
{
    public static class AuthorizationServiceCollectionExtensions
    {
        public static IServiceCollection AddAuthorizationServices(this IServiceCollection services)
        {
            // Deny by default: any endpoint without an explicit [AllowAnonymous] requires auth.
            services.AddAuthorization(options =>
            {
                options.FallbackPolicy = new AuthorizationPolicyBuilder()
                    .RequireAuthenticatedUser()
                    .Build();
            });

            services.AddCustomFieldAuthorization();
            services.AddCustomFeatureAuthorization();

            return services;
        }
    }
}
