using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.DAL.Migrations
{
    /// <inheritdoc />
    public partial class editagain : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DayOfWeek",
                table: "Meetings",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AlterColumn<TimeOnly>(
                name: "Weekly_appointment",
                table: "Meetings",
                type: "time",
                nullable: false,
                oldClrType: typeof(DateTime),
                oldType: "datetime2");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<DateTime>(
                name: "Weekly_appointment",
                table: "Meetings",
                type: "datetime2",
                nullable: false,
                oldClrType: typeof(TimeOnly),
                oldType: "time");

            migrationBuilder.DropColumn(
                name: "DayOfWeek",
                table: "Meetings");
        }
    }
}
