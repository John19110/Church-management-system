using System;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Church.DAL.DBcontext;

#nullable disable

namespace Church.DAL.Migrations
{
    [DbContext(typeof(ProgramContext))]
    [Migration("20261113120000_AddOptionalModulesAndStock")]
    public partial class AddOptionalModulesAndStock : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "OrganizationModuleActivations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ModuleId = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    IsEnabled = table.Column<bool>(type: "bit", nullable: false),
                    EnabledAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    DisabledAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    UpdatedBy = table.Column<string>(type: "nvarchar(450)", maxLength: 450, nullable: true),
                    UpdatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_OrganizationModuleActivations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_OrganizationModuleActivations_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_OrganizationModuleActivations_Meetings_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Meetings",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "StockItems",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    NameAr = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    Description = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: true),
                    DescriptionAr = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: true),
                    Amount = table.Column<int>(type: "int", nullable: false),
                    ImageFileName = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: true),
                    ImageUrl = table.Column<string>(type: "nvarchar(1024)", maxLength: 1024, nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedBy = table.Column<string>(type: "nvarchar(450)", maxLength: 450, nullable: true),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_StockItems", x => x.Id);
                    table.CheckConstraint("CK_StockItems_Amount_NonNegative", "[Amount] >= 0");
                    table.ForeignKey(
                        name: "FK_StockItems_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_StockItems_Meetings_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Meetings",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_OrganizationModuleActivations_ChurchId",
                table: "OrganizationModuleActivations",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_OrganizationModuleActivations_MeetingId",
                table: "OrganizationModuleActivations",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_OrganizationModuleActivations_ModuleId",
                table: "OrganizationModuleActivations",
                column: "ModuleId");

            // SQL Server treats NULLs as distinct in unique indexes, so church-wide
            // (MeetingId null) and meeting-scoped rows need separate filtered indexes.
            migrationBuilder.CreateIndex(
                name: "IX_OrganizationModuleActivations_Module_Church_Wide",
                table: "OrganizationModuleActivations",
                columns: new[] { "ModuleId", "ChurchId" },
                unique: true,
                filter: "[MeetingId] IS NULL AND [ChurchId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_OrganizationModuleActivations_Module_Church_Meeting",
                table: "OrganizationModuleActivations",
                columns: new[] { "ModuleId", "ChurchId", "MeetingId" },
                unique: true,
                filter: "[MeetingId] IS NOT NULL AND [ChurchId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_StockItems_ChurchId",
                table: "StockItems",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_StockItems_ChurchId_MeetingId",
                table: "StockItems",
                columns: new[] { "ChurchId", "MeetingId" });

            migrationBuilder.CreateIndex(
                name: "IX_StockItems_MeetingId",
                table: "StockItems",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_StockItems_Name",
                table: "StockItems",
                column: "Name");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "OrganizationModuleActivations");
            migrationBuilder.DropTable(name: "StockItems");
        }
    }
}
