using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Church.DAL.DBcontext;

#nullable disable

namespace Church.DAL.Migrations
{
    /// <summary>
    /// Junction table: which servants may open the All Members view for a meeting.
    /// </summary>
    [DbContext(typeof(ProgramContext))]
    [Migration("20260922140000_AddMeetingAllMembersViewers")]
    public partial class AddMeetingAllMembersViewers : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "MeetingAllMembersViewers",
                columns: table => new
                {
                    MeetingId = table.Column<int>(type: "int", nullable: false),
                    ServantId = table.Column<int>(type: "int", nullable: false),
                    ChurchId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MeetingAllMembersViewers", x => new { x.MeetingId, x.ServantId });
                    table.ForeignKey(
                        name: "FK_MeetingAllMembersViewers_Meetings_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Meetings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MeetingAllMembersViewers_Servants_ServantId",
                        column: x => x.ServantId,
                        principalTable: "Servants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MeetingAllMembersViewers_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_MeetingAllMembersViewers_ChurchId",
                table: "MeetingAllMembersViewers",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_MeetingAllMembersViewers_ServantId",
                table: "MeetingAllMembersViewers",
                column: "ServantId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "MeetingAllMembersViewers");
        }
    }
}
