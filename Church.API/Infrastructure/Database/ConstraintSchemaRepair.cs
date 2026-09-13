using Church.DAL.DBcontext;
using static Church.API.Infrastructure.Database.DatabaseSchemaUtilities;

namespace Church.API.Infrastructure.Database
{
    /// <summary>
    /// Drops leftover unique indexes/constraints on Churches.Name / Meetings.Name
    /// so duplicate display names are allowed (PublicId remains unique).
    /// </summary>
    internal static class ConstraintSchemaRepair
    {
        public static void Ensure(ProgramContext db, ILogger logger)
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

            logger.LogInformation("Church/Meeting name uniqueness repair completed successfully.");
        }
    }
}
