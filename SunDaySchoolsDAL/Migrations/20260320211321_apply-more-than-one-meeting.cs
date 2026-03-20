using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.DAL.Migrations
{
    /// <inheritdoc />
    public partial class applymorethanonemeeting : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "MeetingId",
                table: "Tools",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MeetingId",
                table: "SpiritualCurriculums",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MeetingId",
                table: "Servants",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MeetingId",
                table: "PhoneCalls",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MeetingId",
                table: "Exams",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MeetingId",
                table: "ExamResults",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MeetingId",
                table: "Classrooms",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ChurchId",
                table: "Churches",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Discriminator",
                table: "Churches",
                type: "nvarchar(8)",
                maxLength: 8,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "MeetingName",
                table: "Churches",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "kind",
                table: "Churches",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MeetingId",
                table: "Children",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MeetingId",
                table: "ChildContacts",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MeetingId",
                table: "AttendanceSessions",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MeetingId",
                table: "AttendanceRecords",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MeetingId",
                table: "AspNetUsers",
                type: "int",
                nullable: true);

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
                name: "IX_Tools_MeetingId",
                table: "Tools",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_SpiritualCurriculums_MeetingId",
                table: "SpiritualCurriculums",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_Servants_MeetingId",
                table: "Servants",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_PhoneCalls_MeetingId",
                table: "PhoneCalls",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_Exams_MeetingId",
                table: "Exams",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_ExamResults_MeetingId",
                table: "ExamResults",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_Classrooms_MeetingId",
                table: "Classrooms",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_Churches_ChurchId",
                table: "Churches",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_Children_MeetingId",
                table: "Children",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_ChildContacts_MeetingId",
                table: "ChildContacts",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceSessions_MeetingId",
                table: "AttendanceSessions",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceRecords_MeetingId",
                table: "AttendanceRecords",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUsers_MeetingId",
                table: "AspNetUsers",
                column: "MeetingId");

            migrationBuilder.AddForeignKey(
                name: "FK_AspNetUsers_Churches_MeetingId",
                table: "AspNetUsers",
                column: "MeetingId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceRecords_Churches_MeetingId",
                table: "AttendanceRecords",
                column: "MeetingId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceSessions_Churches_MeetingId",
                table: "AttendanceSessions",
                column: "MeetingId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_ChildContacts_Churches_MeetingId",
                table: "ChildContacts",
                column: "MeetingId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Children_Churches_MeetingId",
                table: "Children",
                column: "MeetingId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Churches_Churches_ChurchId",
                table: "Churches",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Classrooms_Churches_MeetingId",
                table: "Classrooms",
                column: "MeetingId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_ExamResults_Churches_MeetingId",
                table: "ExamResults",
                column: "MeetingId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Exams_Churches_MeetingId",
                table: "Exams",
                column: "MeetingId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_PhoneCalls_Churches_MeetingId",
                table: "PhoneCalls",
                column: "MeetingId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Servants_Churches_MeetingId",
                table: "Servants",
                column: "MeetingId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_SpiritualCurriculums_Churches_MeetingId",
                table: "SpiritualCurriculums",
                column: "MeetingId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Tools_Churches_MeetingId",
                table: "Tools",
                column: "MeetingId",
                principalTable: "Churches",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AspNetUsers_Churches_MeetingId",
                table: "AspNetUsers");

            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceRecords_Churches_MeetingId",
                table: "AttendanceRecords");

            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceSessions_Churches_MeetingId",
                table: "AttendanceSessions");

            migrationBuilder.DropForeignKey(
                name: "FK_ChildContacts_Churches_MeetingId",
                table: "ChildContacts");

            migrationBuilder.DropForeignKey(
                name: "FK_Children_Churches_MeetingId",
                table: "Children");

            migrationBuilder.DropForeignKey(
                name: "FK_Churches_Churches_ChurchId",
                table: "Churches");

            migrationBuilder.DropForeignKey(
                name: "FK_Classrooms_Churches_MeetingId",
                table: "Classrooms");

            migrationBuilder.DropForeignKey(
                name: "FK_ExamResults_Churches_MeetingId",
                table: "ExamResults");

            migrationBuilder.DropForeignKey(
                name: "FK_Exams_Churches_MeetingId",
                table: "Exams");

            migrationBuilder.DropForeignKey(
                name: "FK_PhoneCalls_Churches_MeetingId",
                table: "PhoneCalls");

            migrationBuilder.DropForeignKey(
                name: "FK_Servants_Churches_MeetingId",
                table: "Servants");

            migrationBuilder.DropForeignKey(
                name: "FK_SpiritualCurriculums_Churches_MeetingId",
                table: "SpiritualCurriculums");

            migrationBuilder.DropForeignKey(
                name: "FK_Tools_Churches_MeetingId",
                table: "Tools");

            migrationBuilder.DropIndex(
                name: "IX_Tools_MeetingId",
                table: "Tools");

            migrationBuilder.DropIndex(
                name: "IX_SpiritualCurriculums_MeetingId",
                table: "SpiritualCurriculums");

            migrationBuilder.DropIndex(
                name: "IX_Servants_MeetingId",
                table: "Servants");

            migrationBuilder.DropIndex(
                name: "IX_PhoneCalls_MeetingId",
                table: "PhoneCalls");

            migrationBuilder.DropIndex(
                name: "IX_Exams_MeetingId",
                table: "Exams");

            migrationBuilder.DropIndex(
                name: "IX_ExamResults_MeetingId",
                table: "ExamResults");

            migrationBuilder.DropIndex(
                name: "IX_Classrooms_MeetingId",
                table: "Classrooms");

            migrationBuilder.DropIndex(
                name: "IX_Churches_ChurchId",
                table: "Churches");

            migrationBuilder.DropIndex(
                name: "IX_Children_MeetingId",
                table: "Children");

            migrationBuilder.DropIndex(
                name: "IX_ChildContacts_MeetingId",
                table: "ChildContacts");

            migrationBuilder.DropIndex(
                name: "IX_AttendanceSessions_MeetingId",
                table: "AttendanceSessions");

            migrationBuilder.DropIndex(
                name: "IX_AttendanceRecords_MeetingId",
                table: "AttendanceRecords");

            migrationBuilder.DropIndex(
                name: "IX_AspNetUsers_MeetingId",
                table: "AspNetUsers");

            migrationBuilder.DropColumn(
                name: "MeetingId",
                table: "Tools");

            migrationBuilder.DropColumn(
                name: "MeetingId",
                table: "SpiritualCurriculums");

            migrationBuilder.DropColumn(
                name: "MeetingId",
                table: "Servants");

            migrationBuilder.DropColumn(
                name: "MeetingId",
                table: "PhoneCalls");

            migrationBuilder.DropColumn(
                name: "MeetingId",
                table: "Exams");

            migrationBuilder.DropColumn(
                name: "MeetingId",
                table: "ExamResults");

            migrationBuilder.DropColumn(
                name: "MeetingId",
                table: "Classrooms");

            migrationBuilder.DropColumn(
                name: "ChurchId",
                table: "Churches");

            migrationBuilder.DropColumn(
                name: "Discriminator",
                table: "Churches");

            migrationBuilder.DropColumn(
                name: "MeetingName",
                table: "Churches");

            migrationBuilder.DropColumn(
                name: "kind",
                table: "Churches");

            migrationBuilder.DropColumn(
                name: "MeetingId",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "MeetingId",
                table: "ChildContacts");

            migrationBuilder.DropColumn(
                name: "MeetingId",
                table: "AttendanceSessions");

            migrationBuilder.DropColumn(
                name: "MeetingId",
                table: "AttendanceRecords");

            migrationBuilder.DropColumn(
                name: "MeetingId",
                table: "AspNetUsers");
        }
    }
}
