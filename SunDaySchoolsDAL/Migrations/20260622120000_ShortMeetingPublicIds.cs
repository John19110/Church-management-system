using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.DAL.Migrations
{
    /// <inheritdoc />
    public partial class ShortMeetingPublicIds : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Meetings_PublicId",
                table: "Meetings");

            // Deterministic short codes for legacy GUID rows (bootstrap may refine further).
            migrationBuilder.Sql(
                """
                UPDATE [Meetings]
                SET [PublicId] = 'M' + RIGHT('00000' + CAST([Id] AS varchar(10)), 5)
                WHERE [PublicId] IS NULL
                   OR LEN([PublicId]) > 10
                """);

            migrationBuilder.AlterColumn<string>(
                name: "PublicId",
                table: "Meetings",
                type: "nvarchar(16)",
                maxLength: 16,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(36)",
                oldMaxLength: 36);

            migrationBuilder.CreateIndex(
                name: "IX_Meetings_PublicId",
                table: "Meetings",
                column: "PublicId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Meetings_PublicId",
                table: "Meetings");

            migrationBuilder.AlterColumn<string>(
                name: "PublicId",
                table: "Meetings",
                type: "nvarchar(36)",
                maxLength: 36,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(16)",
                oldMaxLength: 16);

            migrationBuilder.CreateIndex(
                name: "IX_Meetings_PublicId",
                table: "Meetings",
                column: "PublicId",
                unique: true);
        }
    }
}
