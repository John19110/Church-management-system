using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Church.DAL.Migrations
{
    /// <inheritdoc />
    public partial class customattendance : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<bool>(
                name: "HasClassrooms",
                table: "Meetings",
                type: "bit",
                nullable: false,
                oldClrType: typeof(bool),
                oldType: "bit",
                oldDefaultValue: true);

            migrationBuilder.CreateTable(
                name: "AttendanceCriteria",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    DisplayName = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    DisplayNameAr = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    DataType = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AttendanceCriteria", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AttendanceCriteria_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_AttendanceCriteria_Meetings_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Meetings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "AttendanceCriterionResults",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    AttendanceRecordId = table.Column<int>(type: "int", nullable: false),
                    AttendanceCriterionId = table.Column<int>(type: "int", nullable: false),
                    BoolValue = table.Column<bool>(type: "bit", nullable: true),
                    DisplayNameSnapshot = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    DisplayNameArSnapshot = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AttendanceCriterionResults", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AttendanceCriterionResults_AttendanceCriteria_AttendanceCriterionId",
                        column: x => x.AttendanceCriterionId,
                        principalTable: "AttendanceCriteria",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_AttendanceCriterionResults_AttendanceRecords_AttendanceRecordId",
                        column: x => x.AttendanceRecordId,
                        principalTable: "AttendanceRecords",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceCriteria_ChurchId",
                table: "AttendanceCriteria",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceCriteria_MeetingId_Name",
                table: "AttendanceCriteria",
                columns: new[] { "MeetingId", "Name" },
                unique: true,
                filter: "[IsDeleted] = 0");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceCriterionResults_AttendanceCriterionId",
                table: "AttendanceCriterionResults",
                column: "AttendanceCriterionId");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceCriterionResults_AttendanceRecordId_AttendanceCriterionId",
                table: "AttendanceCriterionResults",
                columns: new[] { "AttendanceRecordId", "AttendanceCriterionId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AttendanceCriterionResults");

            migrationBuilder.DropTable(
                name: "AttendanceCriteria");

            migrationBuilder.AlterColumn<bool>(
                name: "HasClassrooms",
                table: "Meetings",
                type: "bit",
                nullable: false,
                defaultValue: true,
                oldClrType: typeof(bool),
                oldType: "bit");
        }
    }
}
