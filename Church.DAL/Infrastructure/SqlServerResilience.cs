using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace Church.DAL.Infrastructure;

/// <summary>
/// Shared SQL Server / Azure SQL Serverless resiliency settings for EF Core.
/// </summary>
public static class SqlServerResilience
{
    public const int MaxRetryCount = 10;
    public static readonly TimeSpan MaxRetryDelay = TimeSpan.FromSeconds(10);
    public const int MinConnectTimeoutSeconds = 120;

    /// <summary>
    /// Ensures the connection string allows time for Azure SQL Serverless to resume after auto-pause.
    /// Does not modify credentials or server name.
    /// </summary>
    public static string PrepareConnectionString(string connectionString)
    {
        var builder = new SqlConnectionStringBuilder(connectionString);
        if (builder.ConnectTimeout < MinConnectTimeoutSeconds)
        {
            builder.ConnectTimeout = MinConnectTimeoutSeconds;
        }

        return builder.ConnectionString;
    }

    public static void ConfigureEfSqlOptions(
        SqlServerDbContextOptionsBuilder sql,
        string migrationsAssemblyName)
    {
        sql.MigrationsAssembly(migrationsAssemblyName);
        sql.EnableRetryOnFailure(
            maxRetryCount: MaxRetryCount,
            maxRetryDelay: MaxRetryDelay,
            errorNumbersToAdd: null);
    }

    /// <summary>
    /// Azure SQL / transient connectivity errors (pause/resume, throttling, timeouts).
    /// </summary>
    public static bool IsTransientSqlError(int errorNumber) => errorNumber switch
    {
        // Timeout / connection
        -2 or 64 or 233 or 10053 or 10054 or 10060 or 11001 => true,
        // Azure SQL transient / pause-resume / capacity
        40197 or 40501 or 40613 or 40143 or 10928 or 10929 => true,
        49918 or 49919 or 49920 => true,
        _ => false,
    };
}
