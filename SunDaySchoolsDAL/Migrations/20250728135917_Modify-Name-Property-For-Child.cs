using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.Migrations
{
    /// <inheritdoc />
    public partial class ModifyNamePropertyForChild : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Name",
                table: "Children",
                newName: "Name3");

            migrationBuilder.AddColumn<string>(
                name: "FullName",
                table: "Children",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Name1",
                table: "Children",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Name2",
                table: "Children",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FullName",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "Name1",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "Name2",
                table: "Children");

            migrationBuilder.RenameColumn(
                name: "Name3",
                table: "Children",
                newName: "Name");
        }
    }
}
