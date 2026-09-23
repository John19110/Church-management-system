using Church.DAL.DBcontext;
using Church.DAL.Infrastructure;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;

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
                // EF Core 10 treats a snapshot/model mismatch as an error inside MigrateAsync.
                // Hand-written migrations in this repo often update Up()/Down() without regenerating
                // ProgramContextModelSnapshot; that abort happens before Kestrel listens and Azure
                // then crash-loops until the 10-minute site-start timeout.
                options.ConfigureWarnings(w =>
                    w.Ignore(RelationalEventId.PendingModelChangesWarning));
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
