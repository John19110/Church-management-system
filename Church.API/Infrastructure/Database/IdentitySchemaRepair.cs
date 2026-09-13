using Church.DAL.DBcontext;
using Microsoft.EntityFrameworkCore;
using static Church.API.Infrastructure.Database.DatabaseSchemaUtilities;

namespace Church.API.Infrastructure.Database
{
    /// <summary>
    /// Defensive repair for AspNetUsers username/phone indexes and PhoneNumber width.
    /// </summary>
    internal static class IdentitySchemaRepair
    {
        public static void Ensure(ProgramContext db, ILogger logger)
        {
            const string table = "AspNetUsers";

            if (IndexExists(db, table, "UserNameIndex"))
            {
                if (IndexIsUnique(db, table, "UserNameIndex"))
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

            logger.LogInformation("User identity index schema verification/repair completed successfully.");
        }
    }
}
