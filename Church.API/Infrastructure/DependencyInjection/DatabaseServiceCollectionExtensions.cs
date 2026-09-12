using Church.DAL.DBcontext;
using Church.DAL.Infrastructure;
using Microsoft.EntityFrameworkCore;

namespace Church.API.Infrastructure.DependencyInjection
{
    public static class DatabaseServiceCollectionExtensions
    {
        public static IServiceCollection AddDatabaseServices(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            services.AddDbContext<ProgramContext>(options =>
            {
                var cs = SqlServerResilience.PrepareConnectionString(
                    configuration.GetConnectionString("cs")
                        ?? throw new InvalidOperationException(
                            "Missing required connection string 'ConnectionStrings:cs'. " +
                            "Set it in appsettings.Production.json or as an environment variable in the hosting environment."));

                // Migrations live in the DAL project (Church.DAL), not in the API host.
                options.UseSqlServer(
                    cs,
                    sql => SqlServerResilience.ConfigureEfSqlOptions(
                        sql,
                        "Church.DAL"));
            });

            return services;
        }
    }
}
