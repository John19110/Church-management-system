using Church.API.Infrastructure.Database;
using Church.DAL.DBcontext;

namespace Church.API.Infrastructure
{
    /// <summary>
    /// Startup orchestrator: apply EF migrations, then run defensive schema repairs for
    /// shared-hosting drift. Individual repairs live under <c>Infrastructure.Database</c>.
    /// </summary>
    public static class DatabaseBootstrap
    {
        public static async Task ApplyMigrationsAndRepairSchemaAsync(
            IServiceProvider services,
            ILogger logger)
        {
            using var scope = services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ProgramContext>();

            DatabaseDiagnostics.LogConnectionTarget(db, logger);
            await MigrationRunner.ApplyPendingMigrationsOrThrowAsync(db, logger);

            try
            {
                await PublicIdSchemaRepair.EnsureAsync(db, services, logger);
            }
            catch (Exception ex)
            {
                logger.LogCritical(
                    ex,
                    "PublicId schema repair failed ({FailureCategory}). API will not work until columns exist.",
                    DatabaseDiagnostics.DescribeDatabaseFailure(ex));
                throw;
            }

            try
            {
                RegistrationSchemaRepair.Ensure(db, logger);
            }
            catch (Exception ex)
            {
                logger.LogCritical(
                    ex,
                    "Registration approval schema repair failed ({FailureCategory}). API will not work until columns exist.",
                    DatabaseDiagnostics.DescribeDatabaseFailure(ex));
                throw;
            }

            try
            {
                CustomFieldSchemaRepair.Ensure(db, logger);
            }
            catch (Exception ex)
            {
                logger.LogCritical(
                    ex,
                    "Custom field definition schema repair failed ({FailureCategory}). API will not work until columns exist.",
                    DatabaseDiagnostics.DescribeDatabaseFailure(ex));
                throw;
            }

            try
            {
                IdentitySchemaRepair.Ensure(db, logger);
            }
            catch (Exception ex)
            {
                logger.LogCritical(
                    ex,
                    "User identity index schema repair failed ({FailureCategory}).",
                    DatabaseDiagnostics.DescribeDatabaseFailure(ex));
                throw;
            }

            try
            {
                ConstraintSchemaRepair.Ensure(db, logger);
            }
            catch (Exception ex)
            {
                logger.LogCritical(
                    ex,
                    "Church/Meeting name uniqueness repair failed ({FailureCategory}).",
                    DatabaseDiagnostics.DescribeDatabaseFailure(ex));
                throw;
            }
        }
    }
}
