using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.DAL.Migrations
{
    /// <inheritdoc />
    public partial class fixedmeetingproblem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceRecords_Meetings_MeetingId",
                table: "AttendanceRecords");

            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceSessions_Meetings_MeetingId",
                table: "AttendanceSessions");

            migrationBuilder.DropForeignKey(
                name: "FK_Classrooms_Meetings_MeetingId",
                table: "Classrooms");

            migrationBuilder.DropForeignKey(
                name: "FK_ExamResults_Meetings_MeetingId",
                table: "ExamResults");

            migrationBuilder.DropForeignKey(
                name: "FK_Exams_Meetings_MeetingId",
                table: "Exams");

            migrationBuilder.DropForeignKey(
                name: "FK_Meetings_Churches_ChurchId",
                table: "Meetings");

            migrationBuilder.DropForeignKey(
                name: "FK_Meetings_Meetings_MeetingId1",
                table: "Meetings");

            migrationBuilder.DropForeignKey(
                name: "FK_MemberContacts_Meetings_MeetingId",
                table: "MemberContacts");

            migrationBuilder.DropForeignKey(
                name: "FK_Members_Meetings_MeetingId",
                table: "Members");

            migrationBuilder.DropForeignKey(
                name: "FK_PhoneCalls_Meetings_MeetingId",
                table: "PhoneCalls");

            migrationBuilder.DropForeignKey(
                name: "FK_Servants_Meetings_MeetingId",
                table: "Servants");

            migrationBuilder.DropForeignKey(
                name: "FK_SpiritualCurriculums_Meetings_MeetingId",
                table: "SpiritualCurriculums");

            migrationBuilder.DropForeignKey(
                name: "FK_Tools_Meetings_MeetingId",
                table: "Tools");

            migrationBuilder.DropIndex(
                name: "IX_Meetings_MeetingId1",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "MeetingId",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "MeetingId1",
                table: "Meetings");

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "Tools",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "SpiritualCurriculums",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "Servants",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "PhoneCalls",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "Members",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "MemberContacts",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "ChurchId",
                table: "Meetings",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "Exams",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "ExamResults",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "Classrooms",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "AttendanceSessions",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "AttendanceRecords",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 1,
                column: "MeetingId",
                value: 0);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 2,
                column: "MeetingId",
                value: 0);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 3,
                column: "MeetingId",
                value: 0);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 4,
                column: "MeetingId",
                value: 0);

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceRecords_Meetings_MeetingId",
                table: "AttendanceRecords",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceSessions_Meetings_MeetingId",
                table: "AttendanceSessions",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Classrooms_Meetings_MeetingId",
                table: "Classrooms",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ExamResults_Meetings_MeetingId",
                table: "ExamResults",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Exams_Meetings_MeetingId",
                table: "Exams",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Meetings_Churches_ChurchId",
                table: "Meetings",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_MemberContacts_Meetings_MeetingId",
                table: "MemberContacts",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Members_Meetings_MeetingId",
                table: "Members",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_PhoneCalls_Meetings_MeetingId",
                table: "PhoneCalls",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Servants_Meetings_MeetingId",
                table: "Servants",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_SpiritualCurriculums_Meetings_MeetingId",
                table: "SpiritualCurriculums",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Tools_Meetings_MeetingId",
                table: "Tools",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceRecords_Meetings_MeetingId",
                table: "AttendanceRecords");

            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceSessions_Meetings_MeetingId",
                table: "AttendanceSessions");

            migrationBuilder.DropForeignKey(
                name: "FK_Classrooms_Meetings_MeetingId",
                table: "Classrooms");

            migrationBuilder.DropForeignKey(
                name: "FK_ExamResults_Meetings_MeetingId",
                table: "ExamResults");

            migrationBuilder.DropForeignKey(
                name: "FK_Exams_Meetings_MeetingId",
                table: "Exams");

            migrationBuilder.DropForeignKey(
                name: "FK_Meetings_Churches_ChurchId",
                table: "Meetings");

            migrationBuilder.DropForeignKey(
                name: "FK_MemberContacts_Meetings_MeetingId",
                table: "MemberContacts");

            migrationBuilder.DropForeignKey(
                name: "FK_Members_Meetings_MeetingId",
                table: "Members");

            migrationBuilder.DropForeignKey(
                name: "FK_PhoneCalls_Meetings_MeetingId",
                table: "PhoneCalls");

            migrationBuilder.DropForeignKey(
                name: "FK_Servants_Meetings_MeetingId",
                table: "Servants");

            migrationBuilder.DropForeignKey(
                name: "FK_SpiritualCurriculums_Meetings_MeetingId",
                table: "SpiritualCurriculums");

            migrationBuilder.DropForeignKey(
                name: "FK_Tools_Meetings_MeetingId",
                table: "Tools");

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "Tools",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "SpiritualCurriculums",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "Servants",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "PhoneCalls",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "Members",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "MemberContacts",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "ChurchId",
                table: "Meetings",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AddColumn<int>(
                name: "MeetingId",
                table: "Meetings",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MeetingId1",
                table: "Meetings",
                type: "int",
                nullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "Exams",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "ExamResults",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "Classrooms",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "AttendanceSessions",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AlterColumn<int>(
                name: "MeetingId",
                table: "AttendanceRecords",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 1,
                column: "MeetingId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 2,
                column: "MeetingId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 3,
                column: "MeetingId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 4,
                column: "MeetingId",
                value: null);

            migrationBuilder.CreateIndex(
                name: "IX_Meetings_MeetingId1",
                table: "Meetings",
                column: "MeetingId1");

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceRecords_Meetings_MeetingId",
                table: "AttendanceRecords",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceSessions_Meetings_MeetingId",
                table: "AttendanceSessions",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Classrooms_Meetings_MeetingId",
                table: "Classrooms",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_ExamResults_Meetings_MeetingId",
                table: "ExamResults",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Exams_Meetings_MeetingId",
                table: "Exams",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Meetings_Churches_ChurchId",
                table: "Meetings",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Meetings_Meetings_MeetingId1",
                table: "Meetings",
                column: "MeetingId1",
                principalTable: "Meetings",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_MemberContacts_Meetings_MeetingId",
                table: "MemberContacts",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Members_Meetings_MeetingId",
                table: "Members",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_PhoneCalls_Meetings_MeetingId",
                table: "PhoneCalls",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Servants_Meetings_MeetingId",
                table: "Servants",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_SpiritualCurriculums_Meetings_MeetingId",
                table: "SpiritualCurriculums",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Tools_Meetings_MeetingId",
                table: "Tools",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id");
        }
    }
}
