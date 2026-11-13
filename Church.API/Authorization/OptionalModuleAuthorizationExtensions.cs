using Church.BLL.Authorization;

namespace Church.API.Authorization
{
    public static class OptionalModuleAuthorizationExtensions
    {
        public static IServiceCollection AddOptionalModuleAuthorization(this IServiceCollection services)
        {
            services.AddAuthorization(options =>
            {
                options.AddPolicy(OptionalModulePolicies.ManageActivation, policy =>
                    policy.RequireRole(OptionalModuleRoles.ActivationManagers));

                options.AddPolicy(OptionalModulePolicies.UseStock, policy =>
                    policy.RequireRole(OptionalModuleRoles.StockUsers));
            });

            return services;
        }
    }
}
