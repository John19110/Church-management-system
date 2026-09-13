using Church.DAL.DBcontext;
using static Church.API.Infrastructure.Database.DatabaseSchemaUtilities;

namespace Church.API.Infrastructure.Database
{
    /// <summary>
    /// Defensive repair for CustomFieldDefinitions columns missing on shared hosting.
    /// </summary>
    internal static class CustomFieldSchemaRepair
    {
        public static void Ensure(ProgramContext db, ILogger logger)
        {
            const string table = "CustomFieldDefinitions";

            EnsureColumn(db, logger, table, "DisplayNameAr", "nvarchar(256) NULL");
            EnsureColumn(
                db,
                logger,
                table,
                "IsPermanentlyDeleted",
                "bit NOT NULL CONSTRAINT [DF_CustomFieldDefinitions_IsPermanentlyDeleted] DEFAULT(0)");

            logger.LogInformation("Custom field definition schema verification/repair completed successfully.");
        }
    }
}
