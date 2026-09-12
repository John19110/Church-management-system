namespace Church.API.Infrastructure.DependencyInjection
{
    public static class CorsServiceCollectionExtensions
    {
        public const string FlutterWebPolicyName = "FlutterWeb";

        public static IServiceCollection AddCorsServices(
            this IServiceCollection services,
            IConfiguration configuration,
            IHostEnvironment environment)
        {
            // Origins come from configuration so production can be locked to the real Flutter Web
            // domain without a rebuild. A wildcard origin is only acceptable in Development.
            var allowedOrigins = configuration
                .GetSection("Cors:AllowedOrigins")
                .Get<string[]>() ?? Array.Empty<string>();

            if (!environment.IsDevelopment() && allowedOrigins.Length == 0)
            {
                throw new InvalidOperationException(
                    "Missing required configuration 'Cors:AllowedOrigins'. Outside Development the API must " +
                    "list the exact Flutter Web origins (e.g. https://app.mychurch.example) instead of allowing any origin.");
            }

            services.AddCors(options =>
            {
                options.AddPolicy(FlutterWebPolicyName, policy =>
                {
                    if (allowedOrigins.Length == 0)
                    {
                        // Development only: local Flutter Web serves from a random localhost port.
                        policy.SetIsOriginAllowed(_ => true);
                    }
                    else
                    {
                        policy.WithOrigins(allowedOrigins);
                    }

                    policy
                        .AllowAnyHeader()
                        .AllowAnyMethod();
                });
            });

            return services;
        }
    }
}
