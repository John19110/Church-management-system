using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Church.DAL.DBcontext;

#nullable disable

namespace Church.DAL.Migrations
{
    /// <summary>
    /// Drops any unique indexes/constraints on Churches.Name or Meetings.Name
    /// so duplicate display names are allowed (entities are keyed by PublicId/Id).
    /// Idempotent: no-op when no such uniqueness exists.
    /// </summary>
    [DbContext(typeof(ProgramContext))]
    [Migration("20260715040000_AllowDuplicateChurchAndMeetingNames")]
    public partial class AllowDuplicateChurchAndMeetingNames : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                DECLARE @sql nvarchar(max) = N'';

                -- Unique indexes that include Name as the sole key column
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

                -- Unique constraints on Name alone
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

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Intentionally empty — duplicate names must remain allowed.
        }
    }
}
