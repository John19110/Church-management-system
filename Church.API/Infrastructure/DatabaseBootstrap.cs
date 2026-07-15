using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Church.BLL.Services;
using Church.DAL.Repository.Interfaces;
using Church.DAL.DBcontext;

namespace Church.API.Infrastructure
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
                EnsureChurchPublicIdColumn(db, services, logger);
                EnsureMeetingPublicIdColumn(db, services, logger);
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

            try
            {
                EnsureCustomFieldDefinitionColumns(db, logger);
                logger.LogInformation("Custom field definition schema verification/repair completed successfully.");
            }
            catch (Exception ex)
            {
                logger.LogCritical(ex, "Custom field definition schema repair failed. API will not work until columns exist.");
                throw;
            }

            try
            {
                EnsureUserIdentityIndexes(db, logger);
                logger.LogInformation("User identity index schema verification/repair completed successfully.");
            }
            catch (Exception ex)
            {
                logger.LogCritical(ex, "User identity index schema repair failed.");
                throw;
            }

            try
            {
                EnsureDuplicateChurchAndMeetingNamesAllowed(db, logger);
                logger.LogInformation("Church/Meeting name uniqueness repair completed successfully.");
            }
            catch (Exception ex)
            {
                logger.LogCritical(ex, "Church/Meeting name uniqueness repair failed.");
                throw;
            }
        }

        /// <summary>
        /// Drops leftover unique indexes/constraints on Churches.Name / Meetings.Name
        /// so duplicate display names are allowed (PublicId remains unique).
        /// </summary>
        private static void EnsureDuplicateChurchAndMeetingNamesAllowed(ProgramContext db, ILogger logger)
        {
            logger.LogInformation(
                "Ensuring Churches.Name and Meetings.Name are not uniquely constrained.");
            TryExecute(
                db,
                logger,
                """
                DECLARE @sql nvarchar(max) = N'';

                SELECT @sql += N'DROP INDEX ' + QUOTENAME(i.name)
                    + N' ON ' + QUOTENAME(OBJECT_SCHEMA_NAME(i.object_id))
                    + N'.' + QUOTENAME(OBJECT_NAME(i.object_id)) + N';'
                FROM sys.indexes i
                WHERE i.is_unique = 1
                  AND i.is_primary_key = 0
                  AND i.is_unique_constraint = 0
                  AND OBJECT_NAME(i.object_id) IN (N'Churches', N'Meetings')
                  AND EXISTS (
                      SELECT 1
                      FROM sys.index_columns ic
                      INNER JOIN sys.columns c
                          ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                      WHERE ic.object_id = i.object_id
                        AND ic.index_id = i.index_id
                        AND c.name = N'Name'
                  )
                  AND NOT EXISTS (
                      SELECT 1
                      FROM sys.index_columns ic2
                      INNER JOIN sys.columns c2
                          ON c2.object_id = ic2.object_id AND c2.column_id = ic2.column_id
                      WHERE ic2.object_id = i.object_id
                        AND ic2.index_id = i.index_id
                        AND c2.name <> N'Name'
                  );

                SELECT @sql += N'ALTER TABLE '
                    + QUOTENAME(OBJECT_SCHEMA_NAME(kc.parent_object_id))
                    + N'.' + QUOTENAME(OBJECT_NAME(kc.parent_object_id))
                    + N' DROP CONSTRAINT ' + QUOTENAME(kc.name) + N';'
                FROM sys.key_constraints kc
                WHERE kc.type = N'UQ'
                  AND OBJECT_NAME(kc.parent_object_id) IN (N'Churches', N'Meetings')
                  AND EXISTS (
                      SELECT 1
                      FROM sys.index_columns ic
                      INNER JOIN sys.columns c
                          ON c.object_id = ic.object_id AND c.column_id = ic.column_id
                      WHERE ic.object_id = kc.parent_object_id
                        AND ic.index_id = kc.unique_index_id
                        AND c.name = N'Name'
                  )
                  AND NOT EXISTS (
                      SELECT 1
                      FROM sys.index_columns ic2
                      INNER JOIN sys.columns c2
                          ON c2.object_id = ic2.object_id AND c2.column_id = ic2.column_id
                      WHERE ic2.object_id = kc.parent_object_id
                        AND ic2.index_id = kc.unique_index_id
                        AND c2.name <> N'Name'
                  );

                IF LEN(@sql) > 0
                    EXEC sp_executesql @sql;
                """);
        }

        /// <summary>
        /// Allows duplicate usernames and enforces unique phone numbers on AspNetUsers.
        /// </summary>
        private static void EnsureUserIdentityIndexes(ProgramContext db, ILogger logger)
        {
            const string table = "AspNetUsers";

            if (IndexExists(db, table, "UserNameIndex"))
            {
                var isUnique = IndexIsUnique(db, table, "UserNameIndex");
                if (isUnique)
                {
                    logger.LogWarning("Dropping unique UserNameIndex to allow duplicate usernames.");
                    TryExecute(db, logger, "DROP INDEX [UserNameIndex] ON [AspNetUsers]");
                    TryExecute(
                        db,
                        logger,
                        """
                        CREATE INDEX [UserNameIndex] ON [AspNetUsers]([NormalizedUserName])
                        WHERE [NormalizedUserName] IS NOT NULL
                        """);
                }
            }

            if (ColumnExists(db, table, "PhoneNumber"))
            {
                var maxLength = db.Database
                    .SqlQueryRaw<int>(
                        """
                        SELECT COALESCE(c.max_length, 0)
                        FROM sys.columns c
                        INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
                        WHERE c.object_id = OBJECT_ID({0}) AND c.name = 'PhoneNumber'
                        """,
                        table)
                    .AsEnumerable()
                    .FirstOrDefault();

                if (maxLength <= 0 || maxLength > 64)
                {
                    logger.LogWarning("Altering AspNetUsers.PhoneNumber to nvarchar(32).");
                    TryExecute(
                        db,
                        logger,
                        "ALTER TABLE [AspNetUsers] ALTER COLUMN [PhoneNumber] nvarchar(32) NULL");
                }
            }

            if (!IndexExists(db, table, "IX_AspNetUsers_PhoneNumber"))
            {
                logger.LogWarning("Creating unique phone index on AspNetUsers.PhoneNumber.");
                TryExecute(
                    db,
                    logger,
                    """
                    CREATE UNIQUE INDEX [IX_AspNetUsers_PhoneNumber] ON [AspNetUsers]([PhoneNumber])
                    WHERE [PhoneNumber] IS NOT NULL AND [PhoneNumber] <> ''
                    """);
            }
        }

        private static bool IndexExists(ProgramContext db, string tableName, string indexName) =>
            db.Database
                .SqlQueryRaw<int>(
                    """
                    SELECT COUNT(1)
                    FROM sys.indexes
                    WHERE name = {0} AND object_id = OBJECT_ID({1})
                    """,
                    indexName,
                    tableName)
                .AsEnumerable()
                .First() > 0;

        private static bool IndexIsUnique(ProgramContext db, string tableName, string indexName) =>
            db.Database
                .SqlQueryRaw<int>(
                    """
                    SELECT COUNT(1)
                    FROM sys.indexes
                    WHERE name = {0}
                      AND object_id = OBJECT_ID({1})
                      AND is_unique = 1
                    """,
                    indexName,
                    tableName)
                .AsEnumerable()
                .First() > 0;

        /// <summary>
        /// Adds bilingual display name and permanent-delete columns to
        /// <c>CustomFieldDefinitions</c> when missing (shared hosting may lack the EF migration).
        /// </summary>
        private static void EnsureCustomFieldDefinitionColumns(ProgramContext db, ILogger logger)
        {
            const string table = "CustomFieldDefinitions";

            EnsureColumn(db, logger, table, "DisplayNameAr", "nvarchar(256) NULL");
            EnsureColumn(
                db,
                logger,
                table,
                "IsPermanentlyDeleted",
                "bit NOT NULL CONSTRAINT [DF_CustomFieldDefinitions_IsPermanentlyDeleted] DEFAULT(0)");
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
            EnsureColumn(db, logger, table, "RequestedMeetingId", "int NULL");
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

            if (IndexExists(db, tableName, indexName))
                return;

            TryExecute(
                db,
                logger,
                $"CREATE UNIQUE INDEX [{indexName}] ON [{tableName}]([PublicId])");
            logger.LogInformation("Created unique index {Index} on {Table}.", indexName, tableName);
        }

        private static void EnsureChurchPublicIdColumn(
            ProgramContext db,
            IServiceProvider services,
            ILogger logger)
        {
            const string tableName = "Churches";
            const string indexName = "IX_Churches_PublicId";

            if (!ColumnExists(db, tableName, "PublicId"))
            {
                TryExecute(db, logger, $"ALTER TABLE [{tableName}] ADD [PublicId] nvarchar(36) NULL");
            }

            BackfillChurchShortPublicIds(services, logger);

            DropIndexIfExists(db, logger, tableName, indexName);

            var maxLength = GetColumnMaxLength(db, tableName, "PublicId");
            if (maxLength is null or > 16)
            {
                TryExecute(
                    db,
                    logger,
                    $"ALTER TABLE [{tableName}] ALTER COLUMN [PublicId] nvarchar(16) NOT NULL");
            }
            else
            {
                EnsureNotNullForColumn(db, logger, tableName, "PublicId", "nvarchar(16)");
            }

            EnsureUniqueIndex(db, logger, tableName, indexName);
        }

        private static void BackfillChurchShortPublicIds(IServiceProvider services, ILogger logger)
        {
            using var scope = services.CreateScope();
            var churchRepository = scope.ServiceProvider.GetRequiredService<IChurchRepository>();
            var churchPublicIdService = scope.ServiceProvider.GetRequiredService<IChurchPublicIdService>();

            var legacyChurches = churchRepository.GetChurchesNeedingShortPublicIdAsync()
                .GetAwaiter()
                .GetResult();

            if (legacyChurches.Count == 0)
            {
                logger.LogInformation("All church PublicIds are already short codes.");
                return;
            }

            logger.LogWarning(
                "Backfilling {Count} church(es) to short PublicIds.",
                legacyChurches.Count);

            foreach (var church in legacyChurches)
            {
                church.PublicId = churchPublicIdService
                    .GenerateUniqueAsync()
                    .GetAwaiter()
                    .GetResult();
                churchRepository.UpdateAsync(church).GetAwaiter().GetResult();
            }

            logger.LogInformation("Church short PublicId backfill completed.");
        }

        private static void EnsureMeetingPublicIdColumn(
            ProgramContext db,
            IServiceProvider services,
            ILogger logger)
        {
            const string tableName = "Meetings";
            const string indexName = "IX_Meetings_PublicId";

            if (!ColumnExists(db, tableName, "PublicId"))
            {
                TryExecute(db, logger, $"ALTER TABLE [{tableName}] ADD [PublicId] nvarchar(36) NULL");
            }

            // GUID/long values must become short codes before the column is narrowed.
            BackfillMeetingShortPublicIds(services, logger);

            DropIndexIfExists(db, logger, tableName, indexName);

            var maxLength = GetColumnMaxLength(db, tableName, "PublicId");
            if (maxLength is null or > 16)
            {
                TryExecute(
                    db,
                    logger,
                    $"ALTER TABLE [{tableName}] ALTER COLUMN [PublicId] nvarchar(16) NOT NULL");
            }
            else
            {
                EnsureNotNullForColumn(db, logger, tableName, "PublicId", "nvarchar(16)");
            }

            EnsureUniqueIndex(db, logger, tableName, indexName);
        }

        private static void BackfillMeetingShortPublicIds(IServiceProvider services, ILogger logger)
        {
            using var scope = services.CreateScope();
            var meetingRepository = scope.ServiceProvider.GetRequiredService<IMeetingRepository>();
            var meetingPublicIdService = scope.ServiceProvider.GetRequiredService<IMeetingPublicIdService>();

            var legacyMeetings = meetingRepository.GetMeetingsNeedingShortPublicIdAsync()
                .GetAwaiter()
                .GetResult();

            if (legacyMeetings.Count == 0)
            {
                logger.LogInformation("All meeting PublicIds are already short codes.");
                return;
            }

            logger.LogWarning(
                "Backfilling {Count} meeting(s) to short PublicIds.",
                legacyMeetings.Count);

            foreach (var meeting in legacyMeetings)
            {
                meeting.PublicId = meetingPublicIdService
                    .GenerateUniqueAsync(meeting.ChurchId)
                    .GetAwaiter()
                    .GetResult();
                meetingRepository.UpdateAsync(meeting).GetAwaiter().GetResult();
            }

            logger.LogInformation("Meeting short PublicId backfill completed.");
        }

        private static void DropIndexIfExists(
            ProgramContext db,
            ILogger logger,
            string tableName,
            string indexName)
        {
            if (!IndexExists(db, tableName, indexName))
                return;

            logger.LogWarning("Dropping index {Index} on {Table} for schema repair.", indexName, tableName);
            TryExecute(db, logger, $"DROP INDEX [{indexName}] ON [{tableName}]");
        }

        private static int? GetColumnMaxLength(ProgramContext db, string tableName, string columnName)
        {
            if (!ColumnExists(db, tableName, columnName))
                return null;

            return db.Database
                .SqlQueryRaw<int?>(
                    """
                    SELECT CHARACTER_MAXIMUM_LENGTH
                    FROM INFORMATION_SCHEMA.COLUMNS
                    WHERE TABLE_NAME = {0} AND COLUMN_NAME = {1}
                    """,
                    tableName,
                    columnName)
                .AsEnumerable()
                .FirstOrDefault();
        }

        private static void EnsureNotNullForColumn(
            ProgramContext db,
            ILogger logger,
            string tableName,
            string columnName,
            string columnType)
        {
            var isNullable = db.Database
                .SqlQueryRaw<int>(
                    """
                    SELECT COUNT(1)
                    FROM sys.columns
                    WHERE object_id = OBJECT_ID({0})
                      AND name = {1}
                      AND is_nullable = 1
                    """,
                    tableName,
                    columnName)
                .AsEnumerable()
                .First();

            if (isNullable == 0)
                return;

            TryExecute(
                db,
                logger,
                $"ALTER TABLE [{tableName}] ALTER COLUMN [{columnName}] {columnType} NOT NULL");
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
