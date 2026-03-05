using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.Migrations
{
    /// <inheritdoc />
    public partial class edittimeanddatecolomn : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "UpdatedAtUtc",
                table: "AttendanceRecords",
                newName: "UpdatedAt");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "UpdatedAt",
                table: "AttendanceRecords",
                newName: "UpdatedAtUtc");
        }
    }
}
