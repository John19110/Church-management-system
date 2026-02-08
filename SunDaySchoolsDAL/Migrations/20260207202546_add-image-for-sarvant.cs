using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.Migrations
{
    /// <inheritdoc />
    public partial class addimageforsarvant : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "ImagePath",
                table: "Servants",
                newName: "ImageUrl");

            migrationBuilder.AddColumn<string>(
                name: "ImageFileName",
                table: "Servants",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ImageFileName",
                table: "Servants");

            migrationBuilder.RenameColumn(
                name: "ImageUrl",
                table: "Servants",
                newName: "ImagePath");
        }
    }
}
