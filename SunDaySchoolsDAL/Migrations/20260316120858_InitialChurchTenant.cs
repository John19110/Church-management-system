using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.Migrations
{
    /// <inheritdoc />
    public partial class InitialChurchTenant : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
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

            migrationBuilder.AddColumn<int>(
                name: "ChurchId",
                table: "Tools",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ChurchId",
                table: "SpiritualCurriculums",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ChurchId",
                table: "Servants",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ChurchId",
                table: "PhoneCalls",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ChurchId",
                table: "Exams",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ChurchId",
                table: "ExamResults",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ChurchId",
                table: "Classrooms",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ChurchId",
                table: "Children",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ChurchId",
                table: "ChildContacts",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ChurchId",
                table: "AttendanceSessions",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ChurchId",
                table: "AttendanceRecords",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SchoolId",
                table: "AspNetUsers",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "Church",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Church", x => x.Id);
                });

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 1,
                column: "ChurchId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 2,
                column: "ChurchId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 3,
                column: "ChurchId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 4,
                column: "ChurchId",
                value: null);

            migrationBuilder.CreateIndex(
                name: "IX_Tools_ChurchId",
                table: "Tools",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_SpiritualCurriculums_ChurchId",
                table: "SpiritualCurriculums",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_Servants_ChurchId",
                table: "Servants",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_PhoneCalls_ChurchId",
                table: "PhoneCalls",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_Exams_ChurchId",
                table: "Exams",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_ExamResults_ChurchId",
                table: "ExamResults",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_Classrooms_ChurchId",
                table: "Classrooms",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_Children_ChurchId",
                table: "Children",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_ChildContacts_ChurchId",
                table: "ChildContacts",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceSessions_ChurchId",
                table: "AttendanceSessions",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceRecords_ChurchId",
                table: "AttendanceRecords",
                column: "ChurchId");

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceRecords_Church_ChurchId",
                table: "AttendanceRecords",
                column: "ChurchId",
                principalTable: "Church",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceSessions_Church_ChurchId",
                table: "AttendanceSessions",
                column: "ChurchId",
                principalTable: "Church",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_ChildContacts_Church_ChurchId",
                table: "ChildContacts",
                column: "ChurchId",
                principalTable: "Church",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Children_Church_ChurchId",
                table: "Children",
                column: "ChurchId",
                principalTable: "Church",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Classrooms_Church_ChurchId",
                table: "Classrooms",
                column: "ChurchId",
                principalTable: "Church",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_ExamResults_Church_ChurchId",
                table: "ExamResults",
                column: "ChurchId",
                principalTable: "Church",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Exams_Church_ChurchId",
                table: "Exams",
                column: "ChurchId",
                principalTable: "Church",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_PhoneCalls_Church_ChurchId",
                table: "PhoneCalls",
                column: "ChurchId",
                principalTable: "Church",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Servants_Church_ChurchId",
                table: "Servants",
                column: "ChurchId",
                principalTable: "Church",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_SpiritualCurriculums_Church_ChurchId",
                table: "SpiritualCurriculums",
                column: "ChurchId",
                principalTable: "Church",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Tools_Church_ChurchId",
                table: "Tools",
                column: "ChurchId",
                principalTable: "Church",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceRecords_Church_ChurchId",
                table: "AttendanceRecords");

            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceSessions_Church_ChurchId",
                table: "AttendanceSessions");

            migrationBuilder.DropForeignKey(
                name: "FK_ChildContacts_Church_ChurchId",
                table: "ChildContacts");

            migrationBuilder.DropForeignKey(
                name: "FK_Children_Church_ChurchId",
                table: "Children");

            migrationBuilder.DropForeignKey(
                name: "FK_Classrooms_Church_ChurchId",
                table: "Classrooms");

            migrationBuilder.DropForeignKey(
                name: "FK_ExamResults_Church_ChurchId",
                table: "ExamResults");

            migrationBuilder.DropForeignKey(
                name: "FK_Exams_Church_ChurchId",
                table: "Exams");

            migrationBuilder.DropForeignKey(
                name: "FK_PhoneCalls_Church_ChurchId",
                table: "PhoneCalls");

            migrationBuilder.DropForeignKey(
                name: "FK_Servants_Church_ChurchId",
                table: "Servants");

            migrationBuilder.DropForeignKey(
                name: "FK_SpiritualCurriculums_Church_ChurchId",
                table: "SpiritualCurriculums");

            migrationBuilder.DropForeignKey(
                name: "FK_Tools_Church_ChurchId",
                table: "Tools");

            migrationBuilder.DropTable(
                name: "Church");

            migrationBuilder.DropIndex(
                name: "IX_Tools_ChurchId",
                table: "Tools");

            migrationBuilder.DropIndex(
                name: "IX_SpiritualCurriculums_ChurchId",
                table: "SpiritualCurriculums");

            migrationBuilder.DropIndex(
                name: "IX_Servants_ChurchId",
                table: "Servants");

            migrationBuilder.DropIndex(
                name: "IX_PhoneCalls_ChurchId",
                table: "PhoneCalls");

            migrationBuilder.DropIndex(
                name: "IX_Exams_ChurchId",
                table: "Exams");

            migrationBuilder.DropIndex(
                name: "IX_ExamResults_ChurchId",
                table: "ExamResults");

            migrationBuilder.DropIndex(
                name: "IX_Classrooms_ChurchId",
                table: "Classrooms");

            migrationBuilder.DropIndex(
                name: "IX_Children_ChurchId",
                table: "Children");

            migrationBuilder.DropIndex(
                name: "IX_ChildContacts_ChurchId",
                table: "ChildContacts");

            migrationBuilder.DropIndex(
                name: "IX_AttendanceSessions_ChurchId",
                table: "AttendanceSessions");

            migrationBuilder.DropIndex(
                name: "IX_AttendanceRecords_ChurchId",
                table: "AttendanceRecords");

            migrationBuilder.DropColumn(
                name: "ChurchId",
                table: "Tools");

            migrationBuilder.DropColumn(
                name: "ChurchId",
                table: "SpiritualCurriculums");

            migrationBuilder.DropColumn(
                name: "ChurchId",
                table: "Servants");

            migrationBuilder.DropColumn(
                name: "ChurchId",
                table: "PhoneCalls");

            migrationBuilder.DropColumn(
                name: "ChurchId",
                table: "Exams");

            migrationBuilder.DropColumn(
                name: "ChurchId",
                table: "ExamResults");

            migrationBuilder.DropColumn(
                name: "ChurchId",
                table: "Classrooms");

            migrationBuilder.DropColumn(
                name: "ChurchId",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "ChurchId",
                table: "ChildContacts");

            migrationBuilder.DropColumn(
                name: "ChurchId",
                table: "AttendanceSessions");

            migrationBuilder.DropColumn(
                name: "ChurchId",
                table: "AttendanceRecords");

            migrationBuilder.DropColumn(
                name: "SchoolId",
                table: "AspNetUsers");

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
    }
}
