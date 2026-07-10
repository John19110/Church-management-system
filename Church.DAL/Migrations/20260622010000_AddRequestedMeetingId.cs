using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Church.DAL.Migrations
{
    /// <inheritdoc />
    public partial class AddRequestedMeetingId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "RequestedMeetingId",
                table: "AspNetUsers",
                type: "int",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "RequestedMeetingId",
                table: "AspNetUsers");
        }
    }
}
