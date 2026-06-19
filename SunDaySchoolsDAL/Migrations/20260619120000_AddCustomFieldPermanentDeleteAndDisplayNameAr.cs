using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.DAL.Migrations
{
    /// <inheritdoc />
    public partial class AddCustomFieldPermanentDeleteAndDisplayNameAr : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DisplayNameAr",
                table: "CustomFieldDefinitions",
                type: "nvarchar(256)",
                maxLength: 256,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsPermanentlyDeleted",
                table: "CustomFieldDefinitions",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DisplayNameAr",
                table: "CustomFieldDefinitions");

            migrationBuilder.DropColumn(
                name: "IsPermanentlyDeleted",
                table: "CustomFieldDefinitions");
        }
    }
}
