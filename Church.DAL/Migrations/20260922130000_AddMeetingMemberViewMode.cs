using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Church.DAL.DBcontext;

#nullable disable

namespace Church.DAL.Migrations
{
    /// <summary>
    /// Adds Meeting.MemberViewMode (default AssignedOnly) so existing meetings
    /// keep current servant member visibility after deploy.
    /// </summary>
    [DbContext(typeof(ProgramContext))]
    [Migration("20260922130000_AddMeetingMemberViewMode")]
    public partial class AddMeetingMemberViewMode : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "MemberViewMode",
                table: "Meetings",
                type: "int",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "MemberViewMode",
                table: "Meetings");
        }
    }
}
