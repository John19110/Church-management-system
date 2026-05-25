using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.DAL.Migrations
{
    /// <inheritdoc />
    public partial class AddCustomFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceSessions_Classrooms_ClassroomId",
                table: "AttendanceSessions");

            migrationBuilder.CreateTable(
                name: "CustomFieldDefinitions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    DisplayName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    EntityName = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    DataType = table.Column<string>(type: "nvarchar(32)", maxLength: 32, nullable: false),
                    IsRequired = table.Column<bool>(type: "bit", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    IsReadOnly = table.Column<bool>(type: "bit", nullable: false),
                    IsHidden = table.Column<bool>(type: "bit", nullable: false),
                    AllowMultipleValues = table.Column<bool>(type: "bit", nullable: false),
                    DefaultValue = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: true),
                    Placeholder = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: true),
                    ValidationRegex = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: true),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedBy = table.Column<string>(type: "nvarchar(450)", maxLength: 450, nullable: true),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CustomFieldDefinitions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CustomFieldDefinitions_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_CustomFieldDefinitions_Meetings_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Meetings",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "CustomFieldOptions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    CustomFieldDefinitionId = table.Column<int>(type: "int", nullable: false),
                    Value = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    DisplayText = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CustomFieldOptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CustomFieldOptions_CustomFieldDefinitions_CustomFieldDefinitionId",
                        column: x => x.CustomFieldDefinitionId,
                        principalTable: "CustomFieldDefinitions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "CustomFieldValues",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    EntityId = table.Column<int>(type: "int", nullable: false),
                    EntityName = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    CustomFieldDefinitionId = table.Column<int>(type: "int", nullable: false),
                    Value = table.Column<string>(type: "nvarchar(max)", maxLength: 8000, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedBy = table.Column<string>(type: "nvarchar(450)", maxLength: 450, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CustomFieldValues", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CustomFieldValues_CustomFieldDefinitions_CustomFieldDefinitionId",
                        column: x => x.CustomFieldDefinitionId,
                        principalTable: "CustomFieldDefinitions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_CustomFieldDefinitions_ChurchId",
                table: "CustomFieldDefinitions",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomFieldDefinitions_EntityName",
                table: "CustomFieldDefinitions",
                column: "EntityName");

            migrationBuilder.CreateIndex(
                name: "IX_CustomFieldDefinitions_EntityName_ChurchId_MeetingId",
                table: "CustomFieldDefinitions",
                columns: new[] { "EntityName", "ChurchId", "MeetingId" });

            migrationBuilder.CreateIndex(
                name: "IX_CustomFieldDefinitions_EntityName_Name_ChurchId_MeetingId",
                table: "CustomFieldDefinitions",
                columns: new[] { "EntityName", "Name", "ChurchId", "MeetingId" },
                unique: true,
                filter: "[ChurchId] IS NOT NULL AND [MeetingId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_CustomFieldDefinitions_MeetingId",
                table: "CustomFieldDefinitions",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomFieldOptions_CustomFieldDefinitionId",
                table: "CustomFieldOptions",
                column: "CustomFieldDefinitionId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomFieldOptions_CustomFieldDefinitionId_Value",
                table: "CustomFieldOptions",
                columns: new[] { "CustomFieldDefinitionId", "Value" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CustomFieldValues_CustomFieldDefinitionId",
                table: "CustomFieldValues",
                column: "CustomFieldDefinitionId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomFieldValues_EntityId",
                table: "CustomFieldValues",
                column: "EntityId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomFieldValues_EntityName",
                table: "CustomFieldValues",
                column: "EntityName");

            migrationBuilder.CreateIndex(
                name: "IX_CustomFieldValues_EntityName_EntityId",
                table: "CustomFieldValues",
                columns: new[] { "EntityName", "EntityId" });

            migrationBuilder.CreateIndex(
                name: "IX_CustomFieldValues_EntityName_EntityId_CustomFieldDefinitionId",
                table: "CustomFieldValues",
                columns: new[] { "EntityName", "EntityId", "CustomFieldDefinitionId" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceSessions_Classrooms_ClassroomId",
                table: "AttendanceSessions",
                column: "ClassroomId",
                principalTable: "Classrooms",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AttendanceSessions_Classrooms_ClassroomId",
                table: "AttendanceSessions");

            migrationBuilder.DropTable(
                name: "CustomFieldOptions");

            migrationBuilder.DropTable(
                name: "CustomFieldValues");

            migrationBuilder.DropTable(
                name: "CustomFieldDefinitions");

            migrationBuilder.AddForeignKey(
                name: "FK_AttendanceSessions_Classrooms_ClassroomId",
                table: "AttendanceSessions",
                column: "ClassroomId",
                principalTable: "Classrooms",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
