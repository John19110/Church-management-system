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

                // Previously any authenticated principal could write custom field values for any
                // in-scope entity id, which bypassed the role gates on the entity's own endpoints.
                options.AddPolicy(CustomFieldPolicies.WriteValues, policy =>
                    policy.RequireRole(CustomFieldRoles.ValueWriters));
            });

            return services;
        }
    }
}
