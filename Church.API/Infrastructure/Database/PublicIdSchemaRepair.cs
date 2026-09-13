using Church.BLL.Services;
using Church.DAL.DBcontext;
using Church.DAL.Repository.Interfaces;
using static Church.API.Infrastructure.Database.DatabaseSchemaUtilities;

namespace Church.API.Infrastructure.Database
{
    /// <summary>
    /// Defensive repair for Churches/Meetings PublicId columns, short-code backfill, and unique indexes.
    /// </summary>
    internal static class PublicIdSchemaRepair
    {
        public static async Task EnsureAsync(ProgramContext db, IServiceProvider services, ILogger logger)
        {
            await EnsureChurchPublicIdColumnAsync(db, services, logger);
            await EnsureMeetingPublicIdColumnAsync(db, services, logger);
            logger.LogInformation("PublicId schema verification/repair completed successfully.");
        }

        private static async Task EnsureChurchPublicIdColumnAsync(
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

            await BackfillChurchShortPublicIdsAsync(services, logger);
            FinalizePublicIdColumn(db, logger, tableName, indexName);
        }

        private static async Task EnsureMeetingPublicIdColumnAsync(
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
            await BackfillMeetingShortPublicIdsAsync(services, logger);
            FinalizePublicIdColumn(db, logger, tableName, indexName);
        }

        /// <summary>
        /// Narrows PublicId to nvarchar(16) NOT NULL and ensures the unique index.
        /// Drops the index only when an ALTER is actually required.
        /// </summary>
        private static void FinalizePublicIdColumn(
            ProgramContext db,
            ILogger logger,
            string tableName,
            string indexName)
        {
            var maxLength = GetColumnMaxLength(db, tableName, "PublicId");
            var needsResize = maxLength is null or > 16;
            var needsNotNull = IsColumnNullable(db, tableName, "PublicId");

            if (needsResize || needsNotNull)
            {
                DropIndexIfExists(db, logger, tableName, indexName);

                if (needsResize)
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
            }

            EnsureUniqueIndex(db, logger, tableName, indexName, "PublicId");
        }

        private static async Task BackfillChurchShortPublicIdsAsync(IServiceProvider services, ILogger logger)
        {
            using var scope = services.CreateScope();
            var churchRepository = scope.ServiceProvider.GetRequiredService<IChurchRepository>();
            var churchPublicIdService = scope.ServiceProvider.GetRequiredService<IChurchPublicIdService>();

            var legacyChurches = await churchRepository.GetChurchesNeedingShortPublicIdAsync();
            if (legacyChurches.Count == 0)
            {
                logger.LogInformation("All church PublicIds are already short codes.");
                return;
            }

            logger.LogWarning("Backfilling {Count} church(es) to short PublicIds.", legacyChurches.Count);

            foreach (var church in legacyChurches)
            {
                church.PublicId = await churchPublicIdService.GenerateUniqueAsync();
                await churchRepository.UpdateAsync(church);
            }

            logger.LogInformation("Church short PublicId backfill completed.");
        }

        private static async Task BackfillMeetingShortPublicIdsAsync(IServiceProvider services, ILogger logger)
        {
            using var scope = services.CreateScope();
            var meetingRepository = scope.ServiceProvider.GetRequiredService<IMeetingRepository>();
            var meetingPublicIdService = scope.ServiceProvider.GetRequiredService<IMeetingPublicIdService>();

            var legacyMeetings = await meetingRepository.GetMeetingsNeedingShortPublicIdAsync();
            if (legacyMeetings.Count == 0)
            {
                logger.LogInformation("All meeting PublicIds are already short codes.");
                return;
            }

            logger.LogWarning("Backfilling {Count} meeting(s) to short PublicIds.", legacyMeetings.Count);

            foreach (var meeting in legacyMeetings)
            {
                meeting.PublicId = await meetingPublicIdService.GenerateUniqueAsync(meeting.ChurchId);
                await meetingRepository.UpdateAsync(meeting);
            }

            logger.LogInformation("Meeting short PublicId backfill completed.");
        }
    }
}
