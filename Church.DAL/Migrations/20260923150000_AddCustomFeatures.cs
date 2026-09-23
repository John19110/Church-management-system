using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Church.DAL.DBcontext;

#nullable disable

namespace Church.DAL.Migrations
{
    [DbContext(typeof(ProgramContext))]
    [Migration("20260923150000_AddCustomFeatures")]
    public partial class AddCustomFeatures : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "CustomFeatures",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    DisplayName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    DisplayNameAr = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedBy = table.Column<string>(type: "nvarchar(450)", maxLength: 450, nullable: true),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CustomFeatures", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CustomFeatures_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_CustomFeatures_Meetings_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Meetings",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "CustomEntities",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FeatureId = table.Column<int>(type: "int", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    DisplayName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    DisplayNameAr = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    PluralDisplayName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    PluralDisplayNameAr = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedBy = table.Column<string>(type: "nvarchar(450)", maxLength: 450, nullable: true),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CustomEntities", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CustomEntities_CustomFeatures_FeatureId",
                        column: x => x.FeatureId,
                        principalTable: "CustomFeatures",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CustomEntities_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_CustomEntities_Meetings_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Meetings",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "CustomEntityFields",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    EntityId = table.Column<int>(type: "int", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    DisplayName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    DisplayNameAr = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    FieldType = table.Column<string>(type: "nvarchar(32)", maxLength: 32, nullable: false),
                    IsRequired = table.Column<bool>(type: "bit", nullable: false),
                    IsUnique = table.Column<bool>(type: "bit", nullable: false),
                    IsSearchable = table.Column<bool>(type: "bit", nullable: false),
                    ShowOnList = table.Column<bool>(type: "bit", nullable: false),
                    ShowOnForm = table.Column<bool>(type: "bit", nullable: false),
                    ShowOnDetails = table.Column<bool>(type: "bit", nullable: false),
                    DisplayOrder = table.Column<int>(type: "int", nullable: false),
                    Placeholder = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: true),
                    ValidationRegex = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: true),
                    TargetEntityId = table.Column<int>(type: "int", nullable: true),
                    CoreReference = table.Column<string>(type: "nvarchar(16)", maxLength: 16, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedBy = table.Column<string>(type: "nvarchar(450)", maxLength: 450, nullable: true),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CustomEntityFields", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CustomEntityFields_CustomEntities_EntityId",
                        column: x => x.EntityId,
                        principalTable: "CustomEntities",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CustomEntityFields_CustomEntities_TargetEntityId",
                        column: x => x.TargetEntityId,
                        principalTable: "CustomEntities",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_CustomEntityFields_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_CustomEntityFields_Meetings_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Meetings",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "CustomEntityPermissions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    EntityId = table.Column<int>(type: "int", nullable: false),
                    RoleName = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    CanCreate = table.Column<bool>(type: "bit", nullable: false),
                    CanRead = table.Column<bool>(type: "bit", nullable: false),
                    CanUpdate = table.Column<bool>(type: "bit", nullable: false),
                    CanDelete = table.Column<bool>(type: "bit", nullable: false),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CustomEntityPermissions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CustomEntityPermissions_CustomEntities_EntityId",
                        column: x => x.EntityId,
                        principalTable: "CustomEntities",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CustomEntityPermissions_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_CustomEntityPermissions_Meetings_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Meetings",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "CustomEntityRecords",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    EntityId = table.Column<int>(type: "int", nullable: false),
                    DataJson = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedBy = table.Column<string>(type: "nvarchar(450)", maxLength: 450, nullable: true),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CustomEntityRecords", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CustomEntityRecords_CustomEntities_EntityId",
                        column: x => x.EntityId,
                        principalTable: "CustomEntities",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CustomEntityRecords_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_CustomEntityRecords_Meetings_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Meetings",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "CustomEntityFieldOptions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    FieldId = table.Column<int>(type: "int", nullable: false),
                    Value = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    DisplayText = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    DisplayTextAr = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: true),
                    SortOrder = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CustomEntityFieldOptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CustomEntityFieldOptions_CustomEntityFields_FieldId",
                        column: x => x.FieldId,
                        principalTable: "CustomEntityFields",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "CustomEntityRecordReferences",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    RecordId = table.Column<int>(type: "int", nullable: false),
                    FieldId = table.Column<int>(type: "int", nullable: false),
                    TargetKind = table.Column<string>(type: "nvarchar(16)", maxLength: 16, nullable: false),
                    TargetRecordId = table.Column<int>(type: "int", nullable: true),
                    TargetMemberId = table.Column<int>(type: "int", nullable: true),
                    TargetServantId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CustomEntityRecordReferences", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CustomEntityRecordReferences_CustomEntityRecords_RecordId",
                        column: x => x.RecordId,
                        principalTable: "CustomEntityRecords",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CustomEntityRecordReferences_CustomEntityFields_FieldId",
                        column: x => x.FieldId,
                        principalTable: "CustomEntityFields",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_CustomEntityRecordReferences_CustomEntityRecords_TargetRecordId",
                        column: x => x.TargetRecordId,
                        principalTable: "CustomEntityRecords",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_CustomEntityRecordReferences_Members_TargetMemberId",
                        column: x => x.TargetMemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_CustomEntityRecordReferences_Servants_TargetServantId",
                        column: x => x.TargetServantId,
                        principalTable: "Servants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_CustomFeatures_ChurchId",
                table: "CustomFeatures",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomFeatures_MeetingId",
                table: "CustomFeatures",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomFeatures_Church_Name_ChurchWide",
                table: "CustomFeatures",
                columns: new[] { "ChurchId", "Name" },
                unique: true,
                filter: "MeetingId IS NULL");

            migrationBuilder.CreateIndex(
                name: "IX_CustomFeatures_Church_Meeting_Name",
                table: "CustomFeatures",
                columns: new[] { "ChurchId", "MeetingId", "Name" },
                unique: true,
                filter: "MeetingId IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntities_FeatureId",
                table: "CustomEntities",
                column: "FeatureId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntities_ChurchId",
                table: "CustomEntities",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntities_MeetingId",
                table: "CustomEntities",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntities_FeatureId_Name",
                table: "CustomEntities",
                columns: new[] { "FeatureId", "Name" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityFields_EntityId",
                table: "CustomEntityFields",
                column: "EntityId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityFields_ChurchId",
                table: "CustomEntityFields",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityFields_MeetingId",
                table: "CustomEntityFields",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityFields_TargetEntityId",
                table: "CustomEntityFields",
                column: "TargetEntityId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityFields_EntityId_Name",
                table: "CustomEntityFields",
                columns: new[] { "EntityId", "Name" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityFieldOptions_FieldId",
                table: "CustomEntityFieldOptions",
                column: "FieldId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityFieldOptions_FieldId_Value",
                table: "CustomEntityFieldOptions",
                columns: new[] { "FieldId", "Value" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityPermissions_EntityId",
                table: "CustomEntityPermissions",
                column: "EntityId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityPermissions_ChurchId",
                table: "CustomEntityPermissions",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityPermissions_MeetingId",
                table: "CustomEntityPermissions",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityPermissions_EntityId_RoleName",
                table: "CustomEntityPermissions",
                columns: new[] { "EntityId", "RoleName" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityRecords_EntityId",
                table: "CustomEntityRecords",
                column: "EntityId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityRecords_ChurchId",
                table: "CustomEntityRecords",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityRecords_MeetingId",
                table: "CustomEntityRecords",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityRecordReferences_RecordId",
                table: "CustomEntityRecordReferences",
                column: "RecordId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityRecordReferences_FieldId",
                table: "CustomEntityRecordReferences",
                column: "FieldId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityRecordReferences_TargetRecordId",
                table: "CustomEntityRecordReferences",
                column: "TargetRecordId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityRecordReferences_TargetMemberId",
                table: "CustomEntityRecordReferences",
                column: "TargetMemberId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityRecordReferences_TargetServantId",
                table: "CustomEntityRecordReferences",
                column: "TargetServantId");

            migrationBuilder.CreateIndex(
                name: "IX_CustomEntityRecordReferences_UniqueTarget",
                table: "CustomEntityRecordReferences",
                columns: new[] { "RecordId", "FieldId", "TargetRecordId", "TargetMemberId", "TargetServantId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "CustomEntityRecordReferences");
            migrationBuilder.DropTable(name: "CustomEntityFieldOptions");
            migrationBuilder.DropTable(name: "CustomEntityPermissions");
            migrationBuilder.DropTable(name: "CustomEntityRecords");
            migrationBuilder.DropTable(name: "CustomEntityFields");
            migrationBuilder.DropTable(name: "CustomEntities");
            migrationBuilder.DropTable(name: "CustomFeatures");
        }
    }
}
