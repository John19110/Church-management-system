using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.DAL.Migrations
{
    /// <inheritdoc />
    public partial class edittheclassservantrelation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ClassroomServant_Classrooms_ClassroomsId",
                table: "ClassroomServant");

            migrationBuilder.DropForeignKey(
                name: "FK_ClassroomServant_Servants_ServantsId",
                table: "ClassroomServant");

            migrationBuilder.RenameColumn(
                name: "ServantsId",
                table: "ClassroomServant",
                newName: "ClassroomId");

            migrationBuilder.RenameColumn(
                name: "ClassroomsId",
                table: "ClassroomServant",
                newName: "ServantId");

            migrationBuilder.RenameIndex(
                name: "IX_ClassroomServant_ServantsId",
                table: "ClassroomServant",
                newName: "IX_ClassroomServant_ClassroomId");

            migrationBuilder.AddColumn<int>(
                name: "ChurchId",
                table: "ClassroomServant",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MeetingId",
                table: "ClassroomServant",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_ClassroomServant_ChurchId",
                table: "ClassroomServant",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_ClassroomServant_MeetingId",
                table: "ClassroomServant",
                column: "MeetingId");

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

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
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

            migrationBuilder.DropIndex(
                name: "IX_ClassroomServant_ChurchId",
                table: "ClassroomServant");

            migrationBuilder.DropIndex(
                name: "IX_ClassroomServant_MeetingId",
                table: "ClassroomServant");

            migrationBuilder.DropColumn(
                name: "ChurchId",
                table: "ClassroomServant");

            migrationBuilder.DropColumn(
                name: "MeetingId",
                table: "ClassroomServant");

            migrationBuilder.RenameColumn(
                name: "ClassroomId",
                table: "ClassroomServant",
                newName: "ServantsId");

            migrationBuilder.RenameColumn(
                name: "ServantId",
                table: "ClassroomServant",
                newName: "ClassroomsId");

            migrationBuilder.RenameIndex(
                name: "IX_ClassroomServant_ClassroomId",
                table: "ClassroomServant",
                newName: "IX_ClassroomServant_ServantsId");

            migrationBuilder.AddForeignKey(
                name: "FK_ClassroomServant_Classrooms_ClassroomsId",
                table: "ClassroomServant",
                column: "ClassroomsId",
                principalTable: "Classrooms",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ClassroomServant_Servants_ServantsId",
                table: "ClassroomServant",
                column: "ServantsId",
                principalTable: "Servants",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
