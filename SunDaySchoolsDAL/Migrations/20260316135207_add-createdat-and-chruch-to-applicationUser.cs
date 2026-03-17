using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.Migrations
{
    /// <inheritdoc />
    public partial class addcreatedatandchruchtoapplicationUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
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

            migrationBuilder.DropPrimaryKey(
                name: "PK_Church",
                table: "Church");

            migrationBuilder.RenameTable(
                name: "Church",
                newName: "Churches");

            migrationBuilder.RenameColumn(
                name: "SchoolId",
                table: "AspNetUsers",
                newName: "ChurchId");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "AspNetUsers",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<bool>(
                name: "IsApproved",
                table: "AspNetUsers",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddPrimaryKey(
                name: "PK_Churches",
                table: "Churches",
                column: "Id");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUsers_ChurchId",
                table: "AspNetUsers",
                column: "ChurchId");

            migrationBuilder.AddForeignKey(
                name: "FK_AspNetUsers_Churches_ChurchId",
                table: "AspNetUsers",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceRecords_Churches_ChurchId",
                table: "AttendanceRecords",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceSessions_Churches_ChurchId",
                table: "AttendanceSessions",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_ChildContacts_Churches_ChurchId",
                table: "ChildContacts",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Children_Churches_ChurchId",
                table: "Children",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Classrooms_Churches_ChurchId",
                table: "Classrooms",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_ExamResults_Churches_ChurchId",
                table: "ExamResults",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Exams_Churches_ChurchId",
                table: "Exams",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_PhoneCalls_Churches_ChurchId",
                table: "PhoneCalls",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Servants_Churches_ChurchId",
                table: "Servants",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_SpiritualCurriculums_Churches_ChurchId",
                table: "SpiritualCurriculums",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Tools_Churches_ChurchId",
                table: "Tools",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AspNetUsers_Churches_ChurchId",
                table: "AspNetUsers");

            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceRecords_Churches_ChurchId",
                table: "AttendanceRecords");

            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceSessions_Churches_ChurchId",
                table: "AttendanceSessions");

            migrationBuilder.DropForeignKey(
                name: "FK_ChildContacts_Churches_ChurchId",
                table: "ChildContacts");

            migrationBuilder.DropForeignKey(
                name: "FK_Children_Churches_ChurchId",
                table: "Children");

            migrationBuilder.DropForeignKey(
                name: "FK_Classrooms_Churches_ChurchId",
                table: "Classrooms");

            migrationBuilder.DropForeignKey(
                name: "FK_ExamResults_Churches_ChurchId",
                table: "ExamResults");

            migrationBuilder.DropForeignKey(
                name: "FK_Exams_Churches_ChurchId",
                table: "Exams");

            migrationBuilder.DropForeignKey(
                name: "FK_PhoneCalls_Churches_ChurchId",
                table: "PhoneCalls");

            migrationBuilder.DropForeignKey(
                name: "FK_Servants_Churches_ChurchId",
                table: "Servants");

            migrationBuilder.DropForeignKey(
                name: "FK_SpiritualCurriculums_Churches_ChurchId",
                table: "SpiritualCurriculums");

            migrationBuilder.DropForeignKey(
                name: "FK_Tools_Churches_ChurchId",
                table: "Tools");

            migrationBuilder.DropIndex(
                name: "IX_AspNetUsers_ChurchId",
                table: "AspNetUsers");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Churches",
                table: "Churches");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "AspNetUsers");

            migrationBuilder.DropColumn(
                name: "IsApproved",
                table: "AspNetUsers");

            migrationBuilder.RenameTable(
                name: "Churches",
                newName: "Church");

            migrationBuilder.RenameColumn(
                name: "ChurchId",
                table: "AspNetUsers",
                newName: "SchoolId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Church",
                table: "Church",
                column: "Id");

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
    }
}
