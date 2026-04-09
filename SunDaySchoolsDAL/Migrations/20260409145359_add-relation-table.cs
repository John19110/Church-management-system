using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.DAL.Migrations
{
    /// <inheritdoc />
    public partial class addrelationtable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ClassroomServant_Churches_ChurchId",
                table: "ClassroomServant");

            migrationBuilder.DropForeignKey(
                name: "FK_ClassroomServant_Classrooms_ClassroomId",
                table: "ClassroomServant");

            migrationBuilder.DropForeignKey(
                name: "FK_ClassroomServant_Meetings_MeetingId",
                table: "ClassroomServant");

            migrationBuilder.DropForeignKey(
                name: "FK_ClassroomServant_Servants_ServantId",
                table: "ClassroomServant");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ClassroomServant",
                table: "ClassroomServant");

            migrationBuilder.RenameTable(
                name: "ClassroomServant",
                newName: "ClassroomServants");

            migrationBuilder.RenameIndex(
                name: "IX_ClassroomServant_MeetingId",
                table: "ClassroomServants",
                newName: "IX_ClassroomServants_MeetingId");

            migrationBuilder.RenameIndex(
                name: "IX_ClassroomServant_ClassroomId",
                table: "ClassroomServants",
                newName: "IX_ClassroomServants_ClassroomId");

            migrationBuilder.RenameIndex(
                name: "IX_ClassroomServant_ChurchId",
                table: "ClassroomServants",
                newName: "IX_ClassroomServants_ChurchId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ClassroomServants",
                table: "ClassroomServants",
                columns: new[] { "ServantId", "ClassroomId" });

            migrationBuilder.AddForeignKey(
                name: "FK_ClassroomServants_Churches_ChurchId",
                table: "ClassroomServants",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_ClassroomServants_Classrooms_ClassroomId",
                table: "ClassroomServants",
                column: "ClassroomId",
                principalTable: "Classrooms",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ClassroomServants_Meetings_MeetingId",
                table: "ClassroomServants",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_ClassroomServants_Servants_ServantId",
                table: "ClassroomServants",
                column: "ServantId",
                principalTable: "Servants",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ClassroomServants_Churches_ChurchId",
                table: "ClassroomServants");

            migrationBuilder.DropForeignKey(
                name: "FK_ClassroomServants_Classrooms_ClassroomId",
                table: "ClassroomServants");

            migrationBuilder.DropForeignKey(
                name: "FK_ClassroomServants_Meetings_MeetingId",
                table: "ClassroomServants");

            migrationBuilder.DropForeignKey(
                name: "FK_ClassroomServants_Servants_ServantId",
                table: "ClassroomServants");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ClassroomServants",
                table: "ClassroomServants");

            migrationBuilder.RenameTable(
                name: "ClassroomServants",
                newName: "ClassroomServant");

            migrationBuilder.RenameIndex(
                name: "IX_ClassroomServants_MeetingId",
                table: "ClassroomServant",
                newName: "IX_ClassroomServant_MeetingId");

            migrationBuilder.RenameIndex(
                name: "IX_ClassroomServants_ClassroomId",
                table: "ClassroomServant",
                newName: "IX_ClassroomServant_ClassroomId");

            migrationBuilder.RenameIndex(
                name: "IX_ClassroomServants_ChurchId",
                table: "ClassroomServant",
                newName: "IX_ClassroomServant_ChurchId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ClassroomServant",
                table: "ClassroomServant",
                columns: new[] { "ServantId", "ClassroomId" });

            migrationBuilder.AddForeignKey(
                name: "FK_ClassroomServant_Churches_ChurchId",
                table: "ClassroomServant",
                column: "ChurchId",
                principalTable: "Churches",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_ClassroomServant_Classrooms_ClassroomId",
                table: "ClassroomServant",
                column: "ClassroomId",
                principalTable: "Classrooms",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ClassroomServant_Meetings_MeetingId",
                table: "ClassroomServant",
                column: "MeetingId",
                principalTable: "Meetings",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_ClassroomServant_Servants_ServantId",
                table: "ClassroomServant",
                column: "ServantId",
                principalTable: "Servants",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
