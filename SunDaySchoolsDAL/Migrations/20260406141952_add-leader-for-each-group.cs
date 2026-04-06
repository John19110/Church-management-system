using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.DAL.Migrations
{
    /// <inheritdoc />
    public partial class addleaderforeachgroup : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "LeaderServantId",
                table: "Meetings",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "LeaderServantId",
                table: "Classrooms",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "PastorId",
                table: "Churches",
                type: "int",
                nullable: true);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 1,
                column: "LeaderServantId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 2,
                column: "LeaderServantId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 3,
                column: "LeaderServantId",
                value: null);

            migrationBuilder.UpdateData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 4,
                column: "LeaderServantId",
                value: null);

            migrationBuilder.CreateIndex(
                name: "IX_Meetings_LeaderServantId",
                table: "Meetings",
                column: "LeaderServantId");

            migrationBuilder.CreateIndex(
                name: "IX_Classrooms_LeaderServantId",
                table: "Classrooms",
                column: "LeaderServantId");

            migrationBuilder.CreateIndex(
                name: "IX_Churches_PastorId",
                table: "Churches",
                column: "PastorId");

            migrationBuilder.AddForeignKey(
                name: "FK_Churches_Servants_PastorId",
                table: "Churches",
                column: "PastorId",
                principalTable: "Servants",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Classrooms_Servants_LeaderServantId",
                table: "Classrooms",
                column: "LeaderServantId",
                principalTable: "Servants",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Meetings_Servants_LeaderServantId",
                table: "Meetings",
                column: "LeaderServantId",
                principalTable: "Servants",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Churches_Servants_PastorId",
                table: "Churches");

            migrationBuilder.DropForeignKey(
                name: "FK_Classrooms_Servants_LeaderServantId",
                table: "Classrooms");

            migrationBuilder.DropForeignKey(
                name: "FK_Meetings_Servants_LeaderServantId",
                table: "Meetings");

            migrationBuilder.DropIndex(
                name: "IX_Meetings_LeaderServantId",
                table: "Meetings");

            migrationBuilder.DropIndex(
                name: "IX_Classrooms_LeaderServantId",
                table: "Classrooms");

            migrationBuilder.DropIndex(
                name: "IX_Churches_PastorId",
                table: "Churches");

            migrationBuilder.DropColumn(
                name: "LeaderServantId",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "LeaderServantId",
                table: "Classrooms");

            migrationBuilder.DropColumn(
                name: "PastorId",
                table: "Churches");
        }
    }
}
