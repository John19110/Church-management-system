using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.Migrations
{
    /// <inheritdoc />
    public partial class removeattendancesessionintfromclassroom : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AttendanceSessionId",
                table: "Classrooms");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "AttendanceSessionId",
                table: "Classrooms",
                type: "int",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 1,
                column: "AttendanceSessionId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 2,
                column: "AttendanceSessionId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 3,
                column: "AttendanceSessionId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 4,
                column: "AttendanceSessionId",
                value: null);
        }
    }
}
