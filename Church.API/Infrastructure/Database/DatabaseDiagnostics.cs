using Church.DAL.DBcontext;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace Church.API.Infrastructure.Database
{
    /// <summary>
    /// Connection-target logging and SQL failure categorization for startup diagnostics.
    /// Never logs credentials.
    /// </summary>
    internal static class DatabaseDiagnostics
    {
        public static void LogConnectionTarget(ProgramContext db, ILogger logger)
        {
            try
            {
                var builder = new SqlConnectionStringBuilder(db.Database.GetConnectionString());
                logger.LogInformation(
                    "Database bootstrap target — server: {Server}, database: {Database}",
                    builder.DataSource,
                    builder.InitialCatalog);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "Could not read database connection target for diagnostics.");
            }
        }

        public static string DescribeDatabaseFailure(Exception ex)
        {
            var sql = FindSqlException(ex);
            if (sql is not null)
                return DescribeSqlException(sql);

            if (ex is InvalidOperationException
                && ex.Message.Contains("transient failure", StringComparison.OrdinalIgnoreCase))
            {
                return "Transient SQL connection failure (see inner exception)";
            }

            return "Unexpected database error";
        }

        private static SqlException? FindSqlException(Exception ex)
        {
            for (Exception? current = ex; current is not null; current = current.InnerException)
            {
                if (current is SqlException sql)
                    return sql;
            }

            return null;
        }

        private static string DescribeSqlException(SqlException ex) => ex.Number switch
        {
            53 or 11001 => "DNS/server resolution failure",
            10060 or 10061 or -2 or 258 => "TCP connection timeout — server unreachable or port 1433 blocked",
            18456 => "Authentication failure — login rejected",
            4060 => "Database not found on server",
            40615 => "Server unreachable — firewall or network path blocked",
            _ => $"SQL Server error {ex.Number}"
        };
    }
}
