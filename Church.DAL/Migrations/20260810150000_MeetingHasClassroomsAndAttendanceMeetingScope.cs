using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Church.DAL.DBcontext;

#nullable disable

namespace Church.DAL.Migrations
{
    /// <summary>
    /// Adds Meeting.HasClassrooms and scopes AttendanceSession by MeetingId
    /// (ClassroomId becomes optional for meetings without classrooms).
    /// </summary>
    [DbContext(typeof(ProgramContext))]
    [Migration("20260810150000_MeetingHasClassroomsAndAttendanceMeetingScope")]
    public partial class MeetingHasClassroomsAndAttendanceMeetingScope : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "HasClassrooms",
                table: "Meetings",
                type: "bit",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddColumn<int>(
                name: "MeetingId",
                table: "AttendanceSessions",
                type: "int",
                nullable: true);

            migrationBuilder.Sql(
                """
                UPDATE s
                SET s.MeetingId = c.MeetingId
                FROM AttendanceSessions s
                INNER JOIN Classrooms c ON c.Id = s.ClassroomId
                WHERE s.MeetingId IS NULL AND c.MeetingId IS NOT NULL;
                """);

            // Orphan sessions (classroom missing MeetingId) — drop rather than leave invalid rows.
            migrationBuilder.Sql(
                """
                DELETE FROM AttendanceRecords
                WHERE AttendanceSessionId IN (
                    SELECT Id FROM AttendanceSessions WHERE MeetingId IS NULL
                );

                DELETE FROM AttendanceSessions WHERE MeetingId IS NULL;
                """);

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "AttendanceSessions",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceSessions_Classrooms_ClassroomId",
                table: "AttendanceSessions");

            migrationBuilder.AlterColumn<int>(
                name: "ClassroomId",
                table: "AttendanceSessions",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceSessions_MeetingId",
                table: "AttendanceSessions",
                column: "MeetingId");

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceSessions_Meetings_MeetingId",
                table: "AttendanceSessions",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceSessions_Classrooms_ClassroomId",
                table: "AttendanceSessions",
                column: "ClassroomId",
                principalTable: "Classrooms",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceSessions_Meetings_MeetingId",
                table: "AttendanceSessions");

            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceSessions_Classrooms_ClassroomId",
                table: "AttendanceSessions");

            migrationBuilder.DropIndex(
                name: "IX_AttendanceSessions_MeetingId",
                table: "AttendanceSessions");

            migrationBuilder.Sql(
                """
                DELETE FROM AttendanceRecords
                WHERE AttendanceSessionId IN (
                    SELECT Id FROM AttendanceSessions WHERE ClassroomId IS NULL
                );

                DELETE FROM AttendanceSessions WHERE ClassroomId IS NULL;
                """);

            migrationBuilder.DropColumn(
                name: "MeetingId",
                table: "AttendanceSessions");

            migrationBuilder.AlterColumn<int>(
                name: "ClassroomId",
                table: "AttendanceSessions",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceSessions_Classrooms_ClassroomId",
                table: "AttendanceSessions",
                column: "ClassroomId",
                principalTable: "Classrooms",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.DropColumn(
                name: "HasClassrooms",
                table: "Meetings");
        }
    }
}
