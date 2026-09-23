using Church.DAL.DBcontext;
using Microsoft.EntityFrameworkCore;

namespace Church.API.Infrastructure.Database
{
    /// <summary>
    /// Applies pending EF Core migrations. Does not perform defensive schema repair.
    /// </summary>
    internal static class MigrationRunner
    {
        public static async Task ApplyPendingMigrationsOrThrowAsync(ProgramContext db, ILogger logger)
        {
            var applied = db.Database.GetAppliedMigrations().ToList();
            var pending = db.Database.GetPendingMigrations().ToList();

            logger.LogInformation(
                "Database migrations — applied: [{Applied}], pending: [{Pending}]",
                string.Join(", ", applied),
                string.Join(", ", pending));

            if (pending.Count == 0)
                return;

            if (db.Database.HasPendingModelChanges())
            {
                logger.LogWarning(
                    "EF compiled model differs from ProgramContextModelSnapshot. "
                    + "PendingModelChangesWarning is ignored so MigrateAsync can apply "
                    + "pending SQL migration(s): [{Pending}].",
                    string.Join(", ", pending));
            }

            try
            {
                await db.Database.MigrateAsync();
            }
            catch (Exception ex)
            {
                var stillPending = db.Database.GetPendingMigrations().ToList();
                logger.LogCritical(
                    ex,
                    "EF Database.Migrate() failed ({FailureCategory}). Required migration(s) still pending: [{Pending}]. Startup aborted.",
                    DatabaseDiagnostics.DescribeDatabaseFailure(ex),
                    string.Join(", ", stillPending));
                throw;
            }

            pending = db.Database.GetPendingMigrations().ToList();
            if (pending.Count > 0)
            {
                throw new InvalidOperationException(
                    "EF Database.Migrate() returned without applying required migration(s): "
                    + string.Join(", ", pending));
            }

            logger.LogInformation("All pending EF migrations were applied.");
        }
    }
}
