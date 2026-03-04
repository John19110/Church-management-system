using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.Migrations
{
    /// <inheritdoc />
    public partial class renameFromCreatedAtUtcToCreatedAt : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "CreatedAtUtc",
                table: "AttendanceSessions",
                newName: "CreatedAt");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "CreatedAt",
                table: "AttendanceSessions",
                newName: "CreatedAtUtc");
        }
    }
}
