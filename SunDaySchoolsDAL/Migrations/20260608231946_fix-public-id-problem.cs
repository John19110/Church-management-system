using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.DAL.Migrations
{
    /// <inheritdoc />
    public partial class fixpublicidproblem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Idempotent SQL — safe if columns were partially created by a prior deploy or bootstrap.
            migrationBuilder.Sql(
                "IF COL_LENGTH('Churches', 'PublicId') IS NULL ALTER TABLE [Churches] ADD [PublicId] nvarchar(36) NULL;");

            migrationBuilder.Sql(
                "UPDATE [Churches] SET [PublicId] = CONVERT(nvarchar(36), NEWID()) WHERE [PublicId] IS NULL;");

            migrationBuilder.Sql(
                """
                IF EXISTS (
                    SELECT 1 FROM sys.columns
                    WHERE object_id = OBJECT_ID('Churches')
                      AND name = 'PublicId'
                      AND is_nullable = 1)
                ALTER TABLE [Churches] ALTER COLUMN [PublicId] nvarchar(36) NOT NULL;
                """);

            migrationBuilder.Sql(
                """
                IF NOT EXISTS (
                    SELECT 1 FROM sys.indexes
                    WHERE name = 'IX_Churches_PublicId' AND object_id = OBJECT_ID('Churches'))
                CREATE UNIQUE INDEX [IX_Churches_PublicId] ON [Churches]([PublicId]);
                """);

            migrationBuilder.Sql(
                "IF COL_LENGTH('Meetings', 'PublicId') IS NULL ALTER TABLE [Meetings] ADD [PublicId] nvarchar(36) NULL;");

            migrationBuilder.Sql(
                "UPDATE [Meetings] SET [PublicId] = CONVERT(nvarchar(36), NEWID()) WHERE [PublicId] IS NULL;");

            migrationBuilder.Sql(
                """
                IF EXISTS (
                    SELECT 1 FROM sys.columns
                    WHERE object_id = OBJECT_ID('Meetings')
                      AND name = 'PublicId'
                      AND is_nullable = 1)
                ALTER TABLE [Meetings] ALTER COLUMN [PublicId] nvarchar(36) NOT NULL;
                """);

            migrationBuilder.Sql(
                """
                IF NOT EXISTS (
                    SELECT 1 FROM sys.indexes
                    WHERE name = 'IX_Meetings_PublicId' AND object_id = OBJECT_ID('Meetings'))
                CREATE UNIQUE INDEX [IX_Meetings_PublicId] ON [Meetings]([PublicId]);
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                IF EXISTS (
                    SELECT 1 FROM sys.indexes
                    WHERE name = 'IX_Meetings_PublicId' AND object_id = OBJECT_ID('Meetings'))
                DROP INDEX [IX_Meetings_PublicId] ON [Meetings];
                """);

            migrationBuilder.Sql(
                """
                IF COL_LENGTH('Meetings', 'PublicId') IS NOT NULL
                ALTER TABLE [Meetings] DROP COLUMN [PublicId];
                """);

            migrationBuilder.Sql(
                """
                IF EXISTS (
                    SELECT 1 FROM sys.indexes
                    WHERE name = 'IX_Churches_PublicId' AND object_id = OBJECT_ID('Churches'))
                DROP INDEX [IX_Churches_PublicId] ON [Churches];
                """);

            migrationBuilder.Sql(
                """
                IF COL_LENGTH('Churches', 'PublicId') IS NOT NULL
                ALTER TABLE [Churches] DROP COLUMN [PublicId];
                """);
        }
    }
}
