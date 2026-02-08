using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.Migrations
{
    /// <inheritdoc />
    public partial class fixdeleteproblem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ChildContact_Children_ChildId",
                table: "ChildContact");

            migrationBuilder.AlterColumn<int>(
                name: "ChildId",
                table: "ChildContact",
                type: "int",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_ChildContact_Children_ChildId",
                table: "ChildContact",
                column: "ChildId",
                principalTable: "Children",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ChildContact_Children_ChildId",
                table: "ChildContact");

            migrationBuilder.AlterColumn<int>(
                name: "ChildId",
                table: "ChildContact",
                type: "int",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "int");

            migrationBuilder.AddForeignKey(
                name: "FK_ChildContact_Children_ChildId",
                table: "ChildContact",
                column: "ChildId",
                principalTable: "Children",
                principalColumn: "Id");
        }
    }
}
