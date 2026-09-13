using Church.DAL.DBcontext;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace Church.API.Infrastructure.Database
{
    /// <summary>
    /// Low-level, idempotent SQL Server schema helpers used by startup repair classes.
    /// </summary>
    internal static class DatabaseSchemaUtilities
    {
        public static bool ColumnExists(ProgramContext db, string tableName, string columnName) =>
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

        public static bool IndexExists(ProgramContext db, string tableName, string indexName) =>
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

        public static bool IndexIsUnique(ProgramContext db, string tableName, string indexName) =>
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

        public static int? GetColumnMaxLength(ProgramContext db, string tableName, string columnName)
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

        public static bool IsColumnNullable(ProgramContext db, string tableName, string columnName)
        {
            if (!ColumnExists(db, tableName, columnName))
                return true;

            return db.Database
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
                .First() > 0;
        }

        public static void EnsureColumn(
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

        public static void EnsureNotNullForColumn(
            ProgramContext db,
            ILogger logger,
            string tableName,
            string columnName,
            string columnType)
        {
            if (!IsColumnNullable(db, tableName, columnName))
                return;

            TryExecute(
                db,
                logger,
                $"ALTER TABLE [{tableName}] ALTER COLUMN [{columnName}] {columnType} NOT NULL");
        }

        public static void EnsureUniqueIndex(
            ProgramContext db,
            ILogger logger,
            string tableName,
            string indexName,
            string columnName)
        {
            if (!ColumnExists(db, tableName, columnName))
                return;

            if (IndexExists(db, tableName, indexName))
                return;

            TryExecute(
                db,
                logger,
                $"CREATE UNIQUE INDEX [{indexName}] ON [{tableName}]([{columnName}])");
            logger.LogInformation("Created unique index {Index} on {Table}.", indexName, tableName);
        }

        public static void DropIndexIfExists(
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

        public static void TryExecute(ProgramContext db, ILogger logger, string sql)
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
