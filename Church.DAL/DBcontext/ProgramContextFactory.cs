using Microsoft.EntityFrameworkCore;
using Church.DAL.Abstractions;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace Church.DAL.DBcontext
{
    /// <summary>
    /// Used by EF Core CLI / Package Manager Console at design time.
    /// Loads connection settings from the API project's appsettings (composition root).
    /// </summary>
    public class ProgramContextFactory : IDesignTimeDbContextFactory<ProgramContext>
    {
        public ProgramContext CreateDbContext(string[] args)
        {
            var apiProjectPath = Path.GetFullPath(
                Path.Combine(Directory.GetCurrentDirectory(), "..", "Church.API"));

            var environment =
                Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT")
                ?? Environment.GetEnvironmentVariable("DOTNET_ENVIRONMENT")
                ?? "Development";

            var configuration = new ConfigurationBuilder()
                .SetBasePath(apiProjectPath)
                .AddJsonFile("appsettings.json", optional: true)
                .AddJsonFile($"appsettings.{environment}.json", optional: true)
                .AddEnvironmentVariables()
                .Build();

            var connectionString = configuration.GetConnectionString("cs");
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                throw new InvalidOperationException(
                    "Connection string 'cs' is missing or empty. " +
                    "Set ConnectionStrings:cs in Church.API/appsettings.Development.json " +
                    "(or User Secrets) before running update-database.");
            }

            var optionsBuilder = new DbContextOptionsBuilder<ProgramContext>();
            optionsBuilder.UseSqlServer(
                connectionString,
                sql => sql.MigrationsAssembly(typeof(ProgramContext).Assembly.GetName().Name));

            // No HTTP pipeline at design time; accessor is only used for global query filters.
            return new ProgramContext(optionsBuilder.Options, new TenantContextState());
        }
    }
}
