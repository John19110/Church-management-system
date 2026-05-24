using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;

namespace SunDaySchoolsDAL.DBcontext
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
                Path.Combine(Directory.GetCurrentDirectory(), "..", "SunDaySchools.API"));

            var configuration = new ConfigurationBuilder()
                .SetBasePath(apiProjectPath)
                .AddJsonFile("appsettings.json", optional: true)
                .AddJsonFile("appsettings.Development.json", optional: true)
                .AddEnvironmentVariables()
                .Build();

            var connectionString = configuration.GetConnectionString("cs")
                ?? throw new InvalidOperationException(
                    "Connection string 'cs' was not found. " +
                    "Set ConnectionStrings:cs in SunDaySchools.API/appsettings.json.");

            var optionsBuilder = new DbContextOptionsBuilder<ProgramContext>();
            optionsBuilder.UseSqlServer(
                connectionString,
                sql => sql.MigrationsAssembly(typeof(ProgramContext).Assembly.GetName().Name));

            // No HTTP pipeline at design time; accessor is only used for global query filters.
            return new ProgramContext(optionsBuilder.Options, new HttpContextAccessor());
        }
    }
}
