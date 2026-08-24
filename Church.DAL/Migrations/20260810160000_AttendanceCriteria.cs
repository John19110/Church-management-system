using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Church.DAL.DBcontext;

#nullable disable

namespace Church.DAL.Migrations
{
    /// <summary>
    /// Adds meeting-scoped attendance criteria and per-record results, then seeds
    /// has_tools / did_homework from existing HasTools / MadeHomeWork columns.
    ///
    /// Idempotent: <c>20260810124432_custom-attendance</c> already created both
    /// tables on databases that applied it. This migration must still run so EF
    /// records it as applied, without CREATE TABLE (error 2714) or duplicate seed rows.
    /// </summary>
    [DbContext(typeof(ProgramContext))]
    [Migration("20260810160000_AttendanceCriteria")]
    public partial class AttendanceCriteria : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Match the current EF model / custom-attendance schema (nvarchar(450)/max),
            // not a narrower shape, so a DB that skipped custom-attendance still matches
            // ProgramContextModelSnapshot.
            migrationBuilder.Sql(
                """
                IF OBJECT_ID(N'[AttendanceCriteria]', N'U') IS NULL
                BEGIN
                    CREATE TABLE [AttendanceCriteria] (
                        [Id] int NOT NULL IDENTITY,
                        [Name] nvarchar(450) NOT NULL,
                        [DisplayName] nvarchar(max) NOT NULL,
                        [DisplayNameAr] nvarchar(max) NULL,
                        [DataType] int NOT NULL,
                        [IsActive] bit NOT NULL,
                        [IsDeleted] bit NOT NULL,
                        [SortOrder] int NOT NULL,
                        [CreatedAt] datetime2 NOT NULL,
                        [UpdatedAt] datetime2 NULL,
                        [ChurchId] int NULL,
                        [MeetingId] int NOT NULL,
                        CONSTRAINT [PK_AttendanceCriteria] PRIMARY KEY ([Id]),
                        CONSTRAINT [FK_AttendanceCriteria_Churches_ChurchId]
                            FOREIGN KEY ([ChurchId]) REFERENCES [Churches] ([Id]),
                        CONSTRAINT [FK_AttendanceCriteria_Meetings_MeetingId]
                            FOREIGN KEY ([MeetingId]) REFERENCES [Meetings] ([Id]) ON DELETE NO ACTION
                    );

                    CREATE INDEX [IX_AttendanceCriteria_ChurchId]
                        ON [AttendanceCriteria]([ChurchId]);

                    CREATE UNIQUE INDEX [IX_AttendanceCriteria_MeetingId_Name]
                        ON [AttendanceCriteria]([MeetingId], [Name])
                        WHERE [IsDeleted] = 0;
                END
                """);

            migrationBuilder.Sql(
                """
                IF OBJECT_ID(N'[AttendanceCriterionResults]', N'U') IS NULL
                BEGIN
                    CREATE TABLE [AttendanceCriterionResults] (
                        [Id] int NOT NULL IDENTITY,
                        [AttendanceRecordId] int NOT NULL,
                        [AttendanceCriterionId] int NOT NULL,
                        [BoolValue] bit NULL,
                        [DisplayNameSnapshot] nvarchar(max) NOT NULL,
                        [DisplayNameArSnapshot] nvarchar(max) NULL,
                        CONSTRAINT [PK_AttendanceCriterionResults] PRIMARY KEY ([Id]),
                        CONSTRAINT [FK_AttendanceCriterionResults_AttendanceCriteria_AttendanceCriterionId]
                            FOREIGN KEY ([AttendanceCriterionId]) REFERENCES [AttendanceCriteria] ([Id]) ON DELETE NO ACTION,
                        CONSTRAINT [FK_AttendanceCriterionResults_AttendanceRecords_AttendanceRecordId]
                            FOREIGN KEY ([AttendanceRecordId]) REFERENCES [AttendanceRecords] ([Id]) ON DELETE CASCADE
                    );

                    CREATE INDEX [IX_AttendanceCriterionResults_AttendanceCriterionId]
                        ON [AttendanceCriterionResults]([AttendanceCriterionId]);

                    CREATE UNIQUE INDEX [IX_AttendanceCriterionResults_AttendanceRecordId_AttendanceCriterionId]
                        ON [AttendanceCriterionResults]([AttendanceRecordId], [AttendanceCriterionId]);
                END
                """);

            // Seed default criteria per meeting from legacy columns. Skip meetings
            // that already have those names (runtime EnsureDefaultsForMeetingAsync
            // or a previous partial run).
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
                FROM Meetings m
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM AttendanceCriteria c
                    WHERE c.MeetingId = m.Id AND c.Name = N'has_tools'
                );

                INSERT INTO AttendanceCriteria
                    (Name, DisplayName, DisplayNameAr, DataType, IsActive, IsDeleted, SortOrder, CreatedAt, ChurchId, MeetingId)
                SELECT
                    N'did_homework',
                    N'Did homework',
                    N'أدى الواجب',
                    1, 1, 0, 1, SYSUTCDATETIME(),
                    m.ChurchId, m.Id
                FROM Meetings m
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM AttendanceCriteria c
                    WHERE c.MeetingId = m.Id AND c.Name = N'did_homework'
                );
                """);

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
                    ON c.MeetingId = s.MeetingId AND c.Name = N'has_tools' AND c.IsDeleted = 0
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM AttendanceCriterionResults x
                    WHERE x.AttendanceRecordId = r.Id AND x.AttendanceCriterionId = c.Id
                );

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
                    ON c.MeetingId = s.MeetingId AND c.Name = N'did_homework' AND c.IsDeleted = 0
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM AttendanceCriterionResults x
                    WHERE x.AttendanceRecordId = r.Id AND x.AttendanceCriterionId = c.Id
                );
                """);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "AttendanceCriterionResults");
            migrationBuilder.DropTable(name: "AttendanceCriteria");
        }
    }
}
