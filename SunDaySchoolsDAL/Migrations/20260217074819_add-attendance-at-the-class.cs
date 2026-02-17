using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.Migrations
{
    /// <inheritdoc />
    public partial class addattendanceattheclass : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceRecord_AttendanceSession_AttendanceSessionId",
                table: "AttendanceRecord");

            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceRecord_Children_ChildId",
                table: "AttendanceRecord");

            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceSession_Classrooms_ClassroomId",
                table: "AttendanceSession");

            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceSession_Servants_TakenByServantId",
                table: "AttendanceSession");

            migrationBuilder.DropForeignKey(
                name: "FK_ChildContact_Children_ChildId",
                table: "ChildContact");

            migrationBuilder.DropForeignKey(
                name: "FK_Exam_Classrooms_ClassroomId",
                table: "Exam");

            migrationBuilder.DropForeignKey(
                name: "FK_ExamResult_Children_ChildId",
                table: "ExamResult");

            migrationBuilder.DropForeignKey(
                name: "FK_ExamResult_Exam_ExamId",
                table: "ExamResult");

            migrationBuilder.DropForeignKey(
                name: "FK_PhoneCall_ChildContact_ChildContactId",
                table: "PhoneCall");

            migrationBuilder.DropForeignKey(
                name: "FK_PhoneCall_Servants_ServantId",
                table: "PhoneCall");

            migrationBuilder.DropPrimaryKey(
                name: "PK_PhoneCall",
                table: "PhoneCall");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ExamResult",
                table: "ExamResult");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Exam",
                table: "Exam");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ChildContact",
                table: "ChildContact");

            migrationBuilder.DropPrimaryKey(
                name: "PK_AttendanceSession",
                table: "AttendanceSession");

            migrationBuilder.DropPrimaryKey(
                name: "PK_AttendanceRecord",
                table: "AttendanceRecord");

            migrationBuilder.DropIndex(
                name: "IX_AttendanceRecord_AttendanceSessionId",
                table: "AttendanceRecord");

            migrationBuilder.RenameTable(
                name: "PhoneCall",
                newName: "PhoneCalls");

            migrationBuilder.RenameTable(
                name: "ExamResult",
                newName: "ExamResults");

            migrationBuilder.RenameTable(
                name: "Exam",
                newName: "Exams");

            migrationBuilder.RenameTable(
                name: "ChildContact",
                newName: "ChildContacts");

            migrationBuilder.RenameTable(
                name: "AttendanceSession",
                newName: "AttendanceSessions");

            migrationBuilder.RenameTable(
                name: "AttendanceRecord",
                newName: "AttendanceRecords");

            migrationBuilder.RenameIndex(
                name: "IX_PhoneCall_ServantId",
                table: "PhoneCalls",
                newName: "IX_PhoneCalls_ServantId");

            migrationBuilder.RenameIndex(
                name: "IX_PhoneCall_ChildContactId",
                table: "PhoneCalls",
                newName: "IX_PhoneCalls_ChildContactId");

            migrationBuilder.RenameIndex(
                name: "IX_ExamResult_ExamId",
                table: "ExamResults",
                newName: "IX_ExamResults_ExamId");

            migrationBuilder.RenameIndex(
                name: "IX_ExamResult_ChildId",
                table: "ExamResults",
                newName: "IX_ExamResults_ChildId");

            migrationBuilder.RenameIndex(
                name: "IX_Exam_ClassroomId",
                table: "Exams",
                newName: "IX_Exams_ClassroomId");

            migrationBuilder.RenameIndex(
                name: "IX_ChildContact_ChildId",
                table: "ChildContacts",
                newName: "IX_ChildContacts_ChildId");

            migrationBuilder.RenameIndex(
                name: "IX_AttendanceSession_TakenByServantId",
                table: "AttendanceSessions",
                newName: "IX_AttendanceSessions_TakenByServantId");

            migrationBuilder.RenameIndex(
                name: "IX_AttendanceSession_ClassroomId",
                table: "AttendanceSessions",
                newName: "IX_AttendanceSessions_ClassroomId");

            migrationBuilder.RenameIndex(
                name: "IX_AttendanceRecord_ChildId",
                table: "AttendanceRecords",
                newName: "IX_AttendanceRecords_ChildId");

            migrationBuilder.AddColumn<int>(
                name: "AttendanceSessionId",
                table: "Classrooms",
                type: "int",
                nullable: true);

            migrationBuilder.AddPrimaryKey(
                name: "PK_PhoneCalls",
                table: "PhoneCalls",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ExamResults",
                table: "ExamResults",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Exams",
                table: "Exams",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ChildContacts",
                table: "ChildContacts",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_AttendanceSessions",
                table: "AttendanceSessions",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_AttendanceRecords",
                table: "AttendanceRecords",
                column: "Id");

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

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceRecords_AttendanceSessionId_ChildId",
                table: "AttendanceRecords",
                columns: new[] { "AttendanceSessionId", "ChildId" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceRecords_AttendanceSessions_AttendanceSessionId",
                table: "AttendanceRecords",
                column: "AttendanceSessionId",
                principalTable: "AttendanceSessions",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceRecords_Children_ChildId",
                table: "AttendanceRecords",
                column: "ChildId",
                principalTable: "Children",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceSessions_Classrooms_ClassroomId",
                table: "AttendanceSessions",
                column: "ClassroomId",
                principalTable: "Classrooms",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceSessions_Servants_TakenByServantId",
                table: "AttendanceSessions",
                column: "TakenByServantId",
                principalTable: "Servants",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_ChildContacts_Children_ChildId",
                table: "ChildContacts",
                column: "ChildId",
                principalTable: "Children",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ExamResults_Children_ChildId",
                table: "ExamResults",
                column: "ChildId",
                principalTable: "Children",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ExamResults_Exams_ExamId",
                table: "ExamResults",
                column: "ExamId",
                principalTable: "Exams",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Exams_Classrooms_ClassroomId",
                table: "Exams",
                column: "ClassroomId",
                principalTable: "Classrooms",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_PhoneCalls_ChildContacts_ChildContactId",
                table: "PhoneCalls",
                column: "ChildContactId",
                principalTable: "ChildContacts",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_PhoneCalls_Servants_ServantId",
                table: "PhoneCalls",
                column: "ServantId",
                principalTable: "Servants",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceRecords_AttendanceSessions_AttendanceSessionId",
                table: "AttendanceRecords");

            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceRecords_Children_ChildId",
                table: "AttendanceRecords");

            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceSessions_Classrooms_ClassroomId",
                table: "AttendanceSessions");

            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceSessions_Servants_TakenByServantId",
                table: "AttendanceSessions");

            migrationBuilder.DropForeignKey(
                name: "FK_ChildContacts_Children_ChildId",
                table: "ChildContacts");

            migrationBuilder.DropForeignKey(
                name: "FK_ExamResults_Children_ChildId",
                table: "ExamResults");

            migrationBuilder.DropForeignKey(
                name: "FK_ExamResults_Exams_ExamId",
                table: "ExamResults");

            migrationBuilder.DropForeignKey(
                name: "FK_Exams_Classrooms_ClassroomId",
                table: "Exams");

            migrationBuilder.DropForeignKey(
                name: "FK_PhoneCalls_ChildContacts_ChildContactId",
                table: "PhoneCalls");

            migrationBuilder.DropForeignKey(
                name: "FK_PhoneCalls_Servants_ServantId",
                table: "PhoneCalls");

            migrationBuilder.DropPrimaryKey(
                name: "PK_PhoneCalls",
                table: "PhoneCalls");

            migrationBuilder.DropPrimaryKey(
                name: "PK_Exams",
                table: "Exams");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ExamResults",
                table: "ExamResults");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ChildContacts",
                table: "ChildContacts");

            migrationBuilder.DropPrimaryKey(
                name: "PK_AttendanceSessions",
                table: "AttendanceSessions");

            migrationBuilder.DropPrimaryKey(
                name: "PK_AttendanceRecords",
                table: "AttendanceRecords");

            migrationBuilder.DropIndex(
                name: "IX_AttendanceRecords_AttendanceSessionId_ChildId",
                table: "AttendanceRecords");

            migrationBuilder.DropColumn(
                name: "AttendanceSessionId",
                table: "Classrooms");

            migrationBuilder.RenameTable(
                name: "PhoneCalls",
                newName: "PhoneCall");

            migrationBuilder.RenameTable(
                name: "Exams",
                newName: "Exam");

            migrationBuilder.RenameTable(
                name: "ExamResults",
                newName: "ExamResult");

            migrationBuilder.RenameTable(
                name: "ChildContacts",
                newName: "ChildContact");

            migrationBuilder.RenameTable(
                name: "AttendanceSessions",
                newName: "AttendanceSession");

            migrationBuilder.RenameTable(
                name: "AttendanceRecords",
                newName: "AttendanceRecord");

            migrationBuilder.RenameIndex(
                name: "IX_PhoneCalls_ServantId",
                table: "PhoneCall",
                newName: "IX_PhoneCall_ServantId");

            migrationBuilder.RenameIndex(
                name: "IX_PhoneCalls_ChildContactId",
                table: "PhoneCall",
                newName: "IX_PhoneCall_ChildContactId");

            migrationBuilder.RenameIndex(
                name: "IX_Exams_ClassroomId",
                table: "Exam",
                newName: "IX_Exam_ClassroomId");

            migrationBuilder.RenameIndex(
                name: "IX_ExamResults_ExamId",
                table: "ExamResult",
                newName: "IX_ExamResult_ExamId");

            migrationBuilder.RenameIndex(
                name: "IX_ExamResults_ChildId",
                table: "ExamResult",
                newName: "IX_ExamResult_ChildId");

            migrationBuilder.RenameIndex(
                name: "IX_ChildContacts_ChildId",
                table: "ChildContact",
                newName: "IX_ChildContact_ChildId");

            migrationBuilder.RenameIndex(
                name: "IX_AttendanceSessions_TakenByServantId",
                table: "AttendanceSession",
                newName: "IX_AttendanceSession_TakenByServantId");

            migrationBuilder.RenameIndex(
                name: "IX_AttendanceSessions_ClassroomId",
                table: "AttendanceSession",
                newName: "IX_AttendanceSession_ClassroomId");

            migrationBuilder.RenameIndex(
                name: "IX_AttendanceRecords_ChildId",
                table: "AttendanceRecord",
                newName: "IX_AttendanceRecord_ChildId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_PhoneCall",
                table: "PhoneCall",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_Exam",
                table: "Exam",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ExamResult",
                table: "ExamResult",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ChildContact",
                table: "ChildContact",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_AttendanceSession",
                table: "AttendanceSession",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_AttendanceRecord",
                table: "AttendanceRecord",
                column: "Id");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceRecord_AttendanceSessionId",
                table: "AttendanceRecord",
                column: "AttendanceSessionId");

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceRecord_AttendanceSession_AttendanceSessionId",
                table: "AttendanceRecord",
                column: "AttendanceSessionId",
                principalTable: "AttendanceSession",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceRecord_Children_ChildId",
                table: "AttendanceRecord",
                column: "ChildId",
                principalTable: "Children",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceSession_Classrooms_ClassroomId",
                table: "AttendanceSession",
                column: "ClassroomId",
                principalTable: "Classrooms",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceSession_Servants_TakenByServantId",
                table: "AttendanceSession",
                column: "TakenByServantId",
                principalTable: "Servants",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_ChildContact_Children_ChildId",
                table: "ChildContact",
                column: "ChildId",
                principalTable: "Children",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Exam_Classrooms_ClassroomId",
                table: "Exam",
                column: "ClassroomId",
                principalTable: "Classrooms",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_ExamResult_Children_ChildId",
                table: "ExamResult",
                column: "ChildId",
                principalTable: "Children",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ExamResult_Exam_ExamId",
                table: "ExamResult",
                column: "ExamId",
                principalTable: "Exam",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_PhoneCall_ChildContact_ChildContactId",
                table: "PhoneCall",
                column: "ChildContactId",
                principalTable: "ChildContact",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_PhoneCall_Servants_ServantId",
                table: "PhoneCall",
                column: "ServantId",
                principalTable: "Servants",
                principalColumn: "Id");
        }
    }
}
