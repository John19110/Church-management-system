using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.Migrations
{
    /// <inheritdoc />
    public partial class allowservanttohavemorethanoneclass : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Servants_Classrooms_ClassroomId",
                table: "Servants");

            migrationBuilder.DropIndex(
                name: "IX_Servants_ClassroomId",
                table: "Servants");

            migrationBuilder.DropColumn(
                name: "ClassroomId",
                table: "Servants");

            migrationBuilder.AddColumn<string>(
                name: "ClassroomIds",
                table: "Servants",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ClassroomServant",
                columns: table => new
                {
                    ClassroomsId = table.Column<int>(type: "int", nullable: false),
                    ServantsId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ClassroomServant", x => new { x.ClassroomsId, x.ServantsId });
                    table.ForeignKey(
                        name: "FK_ClassroomServant_Classrooms_ClassroomsId",
                        column: x => x.ClassroomsId,
                        principalTable: "Classrooms",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ClassroomServant_Servants_ServantsId",
                        column: x => x.ServantsId,
                        principalTable: "Servants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ClassroomServant_ServantsId",
                table: "ClassroomServant",
                column: "ServantsId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ClassroomServant");

            migrationBuilder.DropColumn(
                name: "ClassroomIds",
                table: "Servants");

            migrationBuilder.AddColumn<int>(
                name: "ClassroomId",
                table: "Servants",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Servants_ClassroomId",
                table: "Servants",
                column: "ClassroomId");

            migrationBuilder.AddForeignKey(
                name: "FK_Servants_Classrooms_ClassroomId",
                table: "Servants",
                column: "ClassroomId",
                principalTable: "Classrooms",
                principalColumn: "Id");
        }
    }
}
