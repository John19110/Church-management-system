using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Church.DAL.Migrations
{
    /// <inheritdoc />
    public partial class ShortChurchPublicIds : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Churches_PublicId",
                table: "Churches");

            migrationBuilder.Sql(
                """
                UPDATE [Churches]
                SET [PublicId] = 'C' + RIGHT('00000' + CAST([Id] AS varchar(10)), 5)
                WHERE [PublicId] IS NULL
                   OR LEN([PublicId]) > 10
                """);

            migrationBuilder.AlterColumn<string>(
                name: "PublicId",
                table: "Churches",
                type: "nvarchar(16)",
                maxLength: 16,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(36)",
                oldMaxLength: 36);

            migrationBuilder.CreateIndex(
                name: "IX_Churches_PublicId",
                table: "Churches",
                column: "PublicId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Churches_PublicId",
                table: "Churches");

            migrationBuilder.AlterColumn<string>(
                name: "PublicId",
                table: "Churches",
                type: "nvarchar(36)",
                maxLength: 36,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(16)",
                oldMaxLength: 16);

            migrationBuilder.CreateIndex(
                name: "IX_Churches_PublicId",
                table: "Churches",
                column: "PublicId",
                unique: true);
        }
    }
}
