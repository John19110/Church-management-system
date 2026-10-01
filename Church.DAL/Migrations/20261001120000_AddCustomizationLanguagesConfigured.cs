using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Church.DAL.DBcontext;

#nullable disable

namespace Church.DAL.Migrations
{
    [DbContext(typeof(ProgramContext))]
    [Migration("20261001120000_AddCustomizationLanguagesConfigured")]
    public partial class AddCustomizationLanguagesConfigured : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsCustomizationLanguagesConfigured",
                table: "Churches",
                type: "bit",
                nullable: false,
                defaultValue: false);

            // Existing churches already have SupportedLanguages from registration/defaults.
            migrationBuilder.Sql(
                """
                UPDATE Churches
                SET IsCustomizationLanguagesConfigured = 1
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsCustomizationLanguagesConfigured",
                table: "Churches");
        }
    }
}
