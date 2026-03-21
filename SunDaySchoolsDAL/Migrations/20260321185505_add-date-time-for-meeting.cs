using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace SunDaySchools.DAL.Migrations
{
    /// <inheritdoc />
    public partial class adddatetimeformeeting : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "Weekly_appointment",
                table: "Meetings",
                type: "datetime2",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.InsertData(
                table: "Classrooms",
                columns: new[] { "Id", "AgeOfMembers", "ChurchId", "MeetingId", "Name", "NumberOfDisplineMembers" },
                values: new object[,]
                {
                    { 1, "حضانه و كيجي", null, null, "الوداعه", null },
                    { 2, "اولي و تانيه", null, null, "السلام", null },
                    { 3, "تالته ورابعه", null, null, "الأيمان", null },
                    { 4, "خامسه و سادسه", null, null, "المحبه", null }
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

            migrationBuilder.DropColumn(
                name: "Weekly_appointment",
                table: "Meetings");
        }
    }
}
