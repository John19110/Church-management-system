using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.DAL.Migrations
{
    /// <inheritdoc />
    public partial class applymembernames : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_PhoneCalls_ChildContacts_ChildContactId",
                table: "PhoneCalls");

            migrationBuilder.DropTable(
                name: "ChildContacts");

            migrationBuilder.RenameColumn(
                name: "ChildContactId",
                table: "PhoneCalls",
                newName: "MemberContactId");

            migrationBuilder.RenameIndex(
                name: "IX_PhoneCalls_ChildContactId",
                table: "PhoneCalls",
                newName: "IX_PhoneCalls_MemberContactId");

            migrationBuilder.CreateTable(
                name: "MemberContacts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Relation = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PhoneNumber = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MemberContacts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MemberContacts_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_MemberContacts_Churches_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_MemberContacts_Members_MemberId",
                        column: x => x.MemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_MemberContacts_ChurchId",
                table: "MemberContacts",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_MemberContacts_MeetingId",
                table: "MemberContacts",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_MemberContacts_MemberId",
                table: "MemberContacts",
                column: "MemberId");

            migrationBuilder.AddForeignKey(
                name: "FK_PhoneCalls_MemberContacts_MemberContactId",
                table: "PhoneCalls",
                column: "MemberContactId",
                principalTable: "MemberContacts",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_PhoneCalls_MemberContacts_MemberContactId",
                table: "PhoneCalls");

            migrationBuilder.DropTable(
                name: "MemberContacts");

            migrationBuilder.RenameColumn(
                name: "MemberContactId",
                table: "PhoneCalls",
                newName: "ChildContactId");

            migrationBuilder.RenameIndex(
                name: "IX_PhoneCalls_MemberContactId",
                table: "PhoneCalls",
                newName: "IX_PhoneCalls_ChildContactId");

            migrationBuilder.CreateTable(
                name: "ChildContacts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ChildId = table.Column<int>(type: "int", nullable: false),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true),
                    PhoneNumber = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Relation = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChildContacts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ChildContacts_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_ChildContacts_Churches_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_ChildContacts_Members_ChildId",
                        column: x => x.ChildId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ChildContacts_ChildId",
                table: "ChildContacts",
                column: "ChildId");

            migrationBuilder.CreateIndex(
                name: "IX_ChildContacts_ChurchId",
                table: "ChildContacts",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_ChildContacts_MeetingId",
                table: "ChildContacts",
                column: "MeetingId");

            migrationBuilder.AddForeignKey(
                name: "FK_PhoneCalls_ChildContacts_ChildContactId",
                table: "PhoneCalls",
                column: "ChildContactId",
                principalTable: "ChildContacts",
                principalColumn: "Id");
        }
    }
}
