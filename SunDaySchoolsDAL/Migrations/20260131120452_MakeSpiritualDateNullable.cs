using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.Migrations
{
    /// <inheritdoc />
    public partial class MakeSpiritualDateNullable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "SpiritualDateOFBirth",
                table: "Children",
                newName: "SpiritualDateOfBirth");

            migrationBuilder.AlterColumn<DateOnly>(
                name: "SpiritualDateOfBirth",
                table: "Children",
                type: "date",
                nullable: true,
                oldClrType: typeof(DateOnly),
                oldType: "date");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "SpiritualDateOfBirth",
                table: "Children",
                newName: "SpiritualDateOFBirth");

            migrationBuilder.AlterColumn<DateOnly>(
                name: "SpiritualDateOFBirth",
                table: "Children",
                type: "date",
                nullable: false,
                defaultValue: new DateOnly(1, 1, 1),
                oldClrType: typeof(DateOnly),
                oldType: "date",
                oldNullable: true);
        }
    }
}
