using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using SunDaySchoolsDAL.DBcontext;

namespace SunDaySchools.API.Infrastructure
{
    /// <summary>
    /// Applies EF migrations and repairs schema when hosting DB is out of sync
    /// (e.g. migration history recorded but columns missing on shared hosting).
    /// </summary>
    public static class DatabaseBootstrap
    {
        public static void ApplyMigrationsAndRepairSchema(IServiceProvider services, ILogger logger)
        {
            using var scope = services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ProgramContext>();

            try
            {
                var applied = db.Database.GetAppliedMigrations().ToList();
                var pending = db.Database.GetPendingMigrations().ToList();

                logger.LogInformation(
                    "Database migrations — applied: [{Applied}], pending: [{Pending}]",
                    string.Join(", ", applied),
                    string.Join(", ", pending));

                if (pending.Count > 0)
                {
                    db.Database.Migrate();
                    logger.LogInformation("Applied {Count} pending EF migration(s).", pending.Count);
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "EF Database.Migrate() failed; running idempotent PublicId schema repair.");
            }

            try
            {
                EnsurePublicIdColumn(db, logger, tableName: "Churches", indexName: "IX_Churches_PublicId");
                EnsurePublicIdColumn(db, logger, tableName: "Meetings", indexName: "IX_Meetings_PublicId");
                logger.LogInformation("PublicId schema verification/repair completed successfully.");
            }
            catch (Exception ex)
            {
                logger.LogCritical(ex, "PublicId schema repair failed. API will not work until columns exist.");
                throw;
            }

            try
            {
                EnsureRegistrationApprovalColumns(db, logger);
                logger.LogInformation("Registration approval schema verification/repair completed successfully.");
            }
            catch (Exception ex)
            {
                logger.LogCritical(ex, "Registration approval schema repair failed. API will not work until columns exist.");
                throw;
            }
        }

        /// <summary>
        /// Adds the church-user approval columns to <c>AspNetUsers</c> when missing
        /// (shared hosting may lack a generated EF migration). Idempotent.
        /// </summary>
        private static void EnsureRegistrationApprovalColumns(ProgramContext db, ILogger logger)
        {
            const string table = "AspNetUsers";

            EnsureColumn(db, logger, table, "RegistrationStatus", "int NOT NULL CONSTRAINT [DF_AspNetUsers_RegistrationStatus] DEFAULT(0)");
            EnsureColumn(db, logger, table, "RequestedChurchId", "int NULL");
            EnsureColumn(db, logger, table, "RequestedMeetingName", "nvarchar(256) NULL");
            EnsureColumn(db, logger, table, "ApprovedByUserId", "nvarchar(450) NULL");
            EnsureColumn(db, logger, table, "ApprovalDate", "datetime2 NULL");
            EnsureColumn(db, logger, table, "RejectionReason", "nvarchar(1024) NULL");
            EnsureColumn(db, logger, table, "RequestedRole", "nvarchar(64) NULL");
            EnsureColumn(db, logger, table, "MeetingAdminPhoneNumber", "nvarchar(32) NULL");
            EnsureColumn(db, logger, table, "ImageUrl", "nvarchar(512) NULL");
            EnsureColumn(db, logger, table, "ImageFileName", "nvarchar(512) NULL");
            EnsureColumn(db, logger, table, "BirthDate", "date NULL");
            EnsureColumn(db, logger, table, "JoiningDate", "date NULL");

            // Backfill: existing approved accounts become Approved; everything else stays Pending(0).
            if (ColumnExists(db, table, "RegistrationStatus") && ColumnExists(db, table, "IsApproved"))
            {
                TryExecute(
                    db,
                    logger,
                    "UPDATE [AspNetUsers] SET [RegistrationStatus] = 1 WHERE [IsApproved] = 1 AND [RegistrationStatus] = 0");
            }
        }

        private static void EnsureColumn(
            ProgramContext db,
            ILogger logger,
            string tableName,
            string columnName,
            string columnDefinition)
        {
            if (ColumnExists(db, tableName, columnName))
                return;

            logger.LogWarning("Table {Table} is missing {Column} — applying schema repair.", tableName, columnName);
            TryExecute(db, logger, $"ALTER TABLE [{tableName}] ADD [{columnName}] {columnDefinition}");
            logger.LogInformation("Ensured {Column} column on {Table}.", columnName, tableName);
        }

        private static void EnsurePublicIdColumn(
            ProgramContext db,
            ILogger logger,
            string tableName,
            string indexName)
        {
            if (ColumnExists(db, tableName, "PublicId"))
            {
                logger.LogInformation("Table {Table} already has PublicId column.", tableName);
                BackfillMissingPublicIds(db, logger, tableName);
                EnsureNotNull(db, logger, tableName);
                EnsureUniqueIndex(db, logger, tableName, indexName);
                return;
            }

            logger.LogWarning("Table {Table} is missing PublicId — applying schema repair.", tableName);

            TryExecute(db, logger, $"ALTER TABLE [{tableName}] ADD [PublicId] nvarchar(36) NULL");
            BackfillMissingPublicIds(db, logger, tableName);
            EnsureNotNull(db, logger, tableName);
            EnsureUniqueIndex(db, logger, tableName, indexName);
            logger.LogInformation("Ensured PublicId column on {Table}.", tableName);
        }

        private static bool ColumnExists(ProgramContext db, string tableName, string columnName) =>
            db.Database
                .SqlQueryRaw<int>(
                    """
                    SELECT COUNT(1)
                    FROM INFORMATION_SCHEMA.COLUMNS
                    WHERE TABLE_NAME = {0} AND COLUMN_NAME = {1}
                    """,
                    tableName,
                    columnName)
                .AsEnumerable()
                .First() > 0;

        private static void BackfillMissingPublicIds(ProgramContext db, ILogger logger, string tableName)
        {
            if (!ColumnExists(db, tableName, "PublicId"))
                return;

            TryExecute(
                db,
                logger,
                $"UPDATE [{tableName}] SET [PublicId] = CONVERT(nvarchar(36), NEWID()) WHERE [PublicId] IS NULL");
        }

        private static void EnsureNotNull(ProgramContext db, ILogger logger, string tableName)
        {
            var isNullable = db.Database
                .SqlQueryRaw<int>(
                    """
                    SELECT COUNT(1)
                    FROM sys.columns
                    WHERE object_id = OBJECT_ID({0})
                      AND name = 'PublicId'
                      AND is_nullable = 1
                    """,
                    tableName)
                .AsEnumerable()
                .First();

            if (isNullable == 0)
                return;

            TryExecute(
                db,
                logger,
                $"ALTER TABLE [{tableName}] ALTER COLUMN [PublicId] nvarchar(36) NOT NULL");
        }

        private static void EnsureUniqueIndex(
            ProgramContext db,
            ILogger logger,
            string tableName,
            string indexName)
        {
            if (!ColumnExists(db, tableName, "PublicId"))
                return;

            var indexExists = db.Database
                .SqlQueryRaw<int>(
                    """
                    SELECT COUNT(1)
                    FROM sys.indexes
                    WHERE name = {0} AND object_id = OBJECT_ID({1})
                    """,
                    indexName,
                    tableName)
                .AsEnumerable()
                .First();

            if (indexExists > 0)
                return;

            TryExecute(
                db,
                logger,
                $"CREATE UNIQUE INDEX [{indexName}] ON [{tableName}]([PublicId])");
            logger.LogInformation("Created unique index {Index} on {Table}.", indexName, tableName);
        }

        private static void TryExecute(ProgramContext db, ILogger logger, string sql)
        {
            try
            {
                db.Database.ExecuteSqlRaw(sql);
            }
            catch (SqlException ex) when (IsBenignSchemaRace(ex))
            {
                logger.LogWarning(
                    ex,
                    "Skipped idempotent schema step because object already exists: {Sql}",
                    sql);
            }
        }

        private static bool IsBenignSchemaRace(SqlException ex) =>
            ex.Message.Contains("specified more than once", StringComparison.OrdinalIgnoreCase)
            || ex.Message.Contains("already an object named", StringComparison.OrdinalIgnoreCase)
            || ex.Message.Contains("already exists", StringComparison.OrdinalIgnoreCase);
    }
}
