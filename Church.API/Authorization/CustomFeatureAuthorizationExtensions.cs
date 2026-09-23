using Church.BLL.Authorization;

namespace Church.API.Authorization
{
    public static class CustomFeatureAuthorizationExtensions
    {
        public static IServiceCollection AddCustomFeatureAuthorization(this IServiceCollection services)
        {
            services.AddAuthorization(options =>
            {
                options.AddPolicy(CustomFeaturePolicies.ManageMetadata, policy =>
                    policy.RequireRole(CustomFeatureRoles.MetadataManagers));

                options.AddPolicy(CustomFeaturePolicies.UseRecords, policy =>
                    policy.RequireRole(CustomFeatureRoles.RecordUsers));
            });

            return services;
        }
    }
}
