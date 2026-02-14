using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.Migrations
{
    /// <inheritdoc />
    public partial class addidentityfields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ApplicationUserId",
                table: "Servants",
                type: "nvarchar(450)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateIndex(
                name: "IX_Servants_ApplicationUserId",
                table: "Servants",
                column: "ApplicationUserId",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Servants_AspNetUsers_ApplicationUserId",
                table: "Servants",
                column: "ApplicationUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Servants_AspNetUsers_ApplicationUserId",
                table: "Servants");

            migrationBuilder.DropIndex(
                name: "IX_Servants_ApplicationUserId",
                table: "Servants");

            migrationBuilder.DropColumn(
                name: "ApplicationUserId",
                table: "Servants");
        }
    }
}
