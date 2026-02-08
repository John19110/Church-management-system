using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.Migrations
{
    /// <inheritdoc />
    public partial class Editphonecall : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "PhoneCall",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ServantId = table.Column<int>(type: "int", nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ChildContactId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PhoneCall", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PhoneCall_ChildContact_ChildContactId",
                        column: x => x.ChildContactId,
                        principalTable: "ChildContact",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_PhoneCall_Servants_ServantId",
                        column: x => x.ServantId,
                        principalTable: "Servants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PhoneCall_ChildContactId",
                table: "PhoneCall",
                column: "ChildContactId");

            migrationBuilder.CreateIndex(
                name: "IX_PhoneCall_ServantId",
                table: "PhoneCall",
                column: "ServantId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PhoneCall");
        }
    }
}
