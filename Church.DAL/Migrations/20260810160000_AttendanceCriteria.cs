using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Church.DAL.DBcontext;

#nullable disable

namespace Church.DAL.Migrations
{
    /// <summary>
    /// Adds meeting-scoped attendance criteria and per-record results.
    /// Seeds has_tools / did_homework from existing HasTools / MadeHomeWork columns.
    /// </summary>
    [DbContext(typeof(ProgramContext))]
    [Migration("20260810160000_AttendanceCriteria")]
    public partial class AttendanceCriteria : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AttendanceCriteria",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    DisplayName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    DisplayNameAr = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
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
                    DisplayNameSnapshot = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    DisplayNameArSnapshot = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true)
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

            // Seed default criteria per meeting from legacy columns.
            migrationBuilder.Sql(
                """
                INSERT INTO AttendanceCriteria
                    (Name, DisplayName, DisplayNameAr, DataType, IsActive, IsDeleted, SortOrder, CreatedAt, ChurchId, MeetingId)
                SELECT
                    N'has_tools',
                    N'Has own tools',
                    N'يملك الأدوات',
                    1, 1, 0, 0, SYSUTCDATETIME(),
                    m.ChurchId, m.Id
                FROM Meetings m;

                INSERT INTO AttendanceCriteria
                    (Name, DisplayName, DisplayNameAr, DataType, IsActive, IsDeleted, SortOrder, CreatedAt, ChurchId, MeetingId)
                SELECT
                    N'did_homework',
                    N'Did homework',
                    N'أدى الواجب',
                    1, 1, 0, 1, SYSUTCDATETIME(),
                    m.ChurchId, m.Id
                FROM Meetings m;
                """);

            // Migrate existing boolean values into criterion results with snapshots.
            migrationBuilder.Sql(
                """
                INSERT INTO AttendanceCriterionResults
                    (AttendanceRecordId, AttendanceCriterionId, BoolValue, DisplayNameSnapshot, DisplayNameArSnapshot)
                SELECT
                    r.Id,
                    c.Id,
                    r.HasTools,
                    c.DisplayName,
                    c.DisplayNameAr
                FROM AttendanceRecords r
                INNER JOIN AttendanceSessions s ON s.Id = r.AttendanceSessionId
                INNER JOIN AttendanceCriteria c
                    ON c.MeetingId = s.MeetingId AND c.Name = N'has_tools' AND c.IsDeleted = 0;

                INSERT INTO AttendanceCriterionResults
                    (AttendanceRecordId, AttendanceCriterionId, BoolValue, DisplayNameSnapshot, DisplayNameArSnapshot)
                SELECT
                    r.Id,
                    c.Id,
                    r.MadeHomeWork,
                    c.DisplayName,
                    c.DisplayNameAr
                FROM AttendanceRecords r
                INNER JOIN AttendanceSessions s ON s.Id = r.AttendanceSessionId
                INNER JOIN AttendanceCriteria c
                    ON c.MeetingId = s.MeetingId AND c.Name = N'did_homework' AND c.IsDeleted = 0;
                """);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "AttendanceCriterionResults");
            migrationBuilder.DropTable(name: "AttendanceCriteria");
        }
    }
}
