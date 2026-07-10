using Church.BLL.Authorization;

namespace Church.API.Authorization
{
    public static class CustomFieldAuthorizationExtensions
    {
        public static IServiceCollection AddCustomFieldAuthorization(this IServiceCollection services)
        {
            services.AddAuthorization(options =>
            {
                options.AddPolicy(CustomFieldPolicies.ManageDefinitions, policy =>
                    policy.RequireRole(CustomFieldRoles.DefinitionManagers));

                options.AddPolicy(CustomFieldPolicies.ReadDefinitions, policy =>
                    policy.RequireAuthenticatedUser());

                options.AddPolicy(CustomFieldPolicies.WriteValues, policy =>
                    policy.RequireAuthenticatedUser());
            });

            return services;
        }
    }
}
