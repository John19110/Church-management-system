using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.Migrations
{
    /// <inheritdoc />
    public partial class addschoolentity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ClassroomIds",
                table: "Servants");

            migrationBuilder.AddColumn<int>(
                name: "SchoolId",
                table: "Tools",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "SchoolId",
                table: "SpiritualCurriculums",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "SchoolId",
                table: "Servants",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "classroomsIds",
                table: "Servants",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "SchoolId",
                table: "PhoneCalls",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "SchoolId",
                table: "Exams",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "SchoolId",
                table: "ExamResults",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "SchoolId",
                table: "Classrooms",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "SchoolId",
                table: "Children",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "SchoolId",
                table: "ChildContacts",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "SchoolId",
                table: "AttendanceSessions",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "SchoolId",
                table: "AttendanceRecords",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 1,
                column: "SchoolId",
                value: 0);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 2,
                column: "SchoolId",
                value: 0);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 3,
                column: "SchoolId",
                value: 0);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 4,
                column: "SchoolId",
                value: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "SchoolId",
                table: "Tools");

            migrationBuilder.DropColumn(
                name: "SchoolId",
                table: "SpiritualCurriculums");

            migrationBuilder.DropColumn(
                name: "SchoolId",
                table: "Servants");

            migrationBuilder.DropColumn(
                name: "classroomsIds",
                table: "Servants");

            migrationBuilder.DropColumn(
                name: "SchoolId",
                table: "PhoneCalls");

            migrationBuilder.DropColumn(
                name: "SchoolId",
                table: "Exams");

            migrationBuilder.DropColumn(
                name: "SchoolId",
                table: "ExamResults");

            migrationBuilder.DropColumn(
                name: "SchoolId",
                table: "Classrooms");

            migrationBuilder.DropColumn(
                name: "SchoolId",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "SchoolId",
                table: "ChildContacts");

            migrationBuilder.DropColumn(
                name: "SchoolId",
                table: "AttendanceSessions");

            migrationBuilder.DropColumn(
                name: "SchoolId",
                table: "AttendanceRecords");

            migrationBuilder.AddColumn<string>(
                name: "ClassroomIds",
                table: "Servants",
                type: "nvarchar(max)",
                nullable: true);
        }
    }
}
