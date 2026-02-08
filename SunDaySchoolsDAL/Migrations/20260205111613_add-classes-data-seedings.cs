using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace SunDaySchools.Migrations
{
    /// <inheritdoc />
    public partial class addclassesdataseedings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Classrooms",
                columns: new[] { "Id", "AgeOfChildren", "Name", "NumberOfDisplineChildren" },
                values: new object[,]
                {
                    { 1, "حضانه و كيجي", "الوداعه", null },
                    { 2, "اولي و تانيه", "السلام", null },
                    { 3, "تالته ورابعه", "الأيمان", null },
                    { 4, "خامسه و سادسه", "المحبه", null }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 1);

            migrationBuilder.DeleteData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 2);

            migrationBuilder.DeleteData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 3);

            migrationBuilder.DeleteData(
                table: "Classrooms",
                keyColumn: "Id",
                keyValue: 4);
        }
    }
}
