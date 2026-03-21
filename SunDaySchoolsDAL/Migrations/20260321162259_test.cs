using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.DAL.Migrations
{
    /// <inheritdoc />
    public partial class test : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
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
                name: "FK_MemberContacts_Churches_MeetingId",
                table: "MemberContacts");

            migrationBuilder.DropForeignKey(
                name: "FK_Members_Churches_MeetingId",
                table: "Members");

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
                name: "IX_Churches_ChurchId",
                table: "Churches");

            migrationBuilder.DropColumn(
                name: "ChurchId",
                table: "Churches");

            migrationBuilder.DropColumn(
                name: "Discriminator",
                table: "Churches");

            migrationBuilder.DropColumn(
                name: "MeetingName",
                table: "Churches");

            migrationBuilder.CreateTable(
                name: "Meetings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId1 = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Meetings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Meetings_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Meetings_Meetings_MeetingId1",
                        column: x => x.MeetingId1,
                        principalTable: "Meetings",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_Meetings_ChurchId",
                table: "Meetings",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_Meetings_MeetingId1",
                table: "Meetings",
                column: "MeetingId1");

            migrationBuilder.AddForeignKey(
                name: "FK_AspNetUsers_Meetings_MeetingId",
                table: "AspNetUsers",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id");

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

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AspNetUsers_Meetings_MeetingId",
                table: "AspNetUsers");

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

            migrationBuilder.DropTable(
                name: "Meetings");

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

            migrationBuilder.CreateIndex(
                name: "IX_Churches_ChurchId",
                table: "Churches",
                column: "ChurchId");

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
                name: "FK_MemberContacts_Churches_MeetingId",
                table: "MemberContacts",
                column: "MeetingId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Members_Churches_MeetingId",
                table: "Members",
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
    }
}
