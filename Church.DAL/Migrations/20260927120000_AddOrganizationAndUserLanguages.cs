using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Church.DAL.DBcontext;

#nullable disable

namespace Church.DAL.Migrations
{
    [DbContext(typeof(ProgramContext))]
    [Migration("20260927120000_AddOrganizationAndUserLanguages")]
    public partial class AddOrganizationAndUserLanguages : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "SupportedLanguages",
                table: "Churches",
                type: "nvarchar(16)",
                maxLength: 16,
                nullable: false,
                defaultValue: "en,ar");

            migrationBuilder.AddColumn<string>(
                name: "DefaultLanguage",
                table: "Churches",
                type: "nvarchar(8)",
                maxLength: 8,
                nullable: false,
                defaultValue: "en");

            migrationBuilder.AddColumn<string>(
                name: "PreferredLanguage",
                table: "AspNetUsers",
                type: "nvarchar(8)",
                maxLength: 8,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "SupportedLanguages",
                table: "Churches");

            migrationBuilder.DropColumn(
                name: "DefaultLanguage",
                table: "Churches");

            migrationBuilder.DropColumn(
                name: "PreferredLanguage",
                table: "AspNetUsers");
        }
    }
}
