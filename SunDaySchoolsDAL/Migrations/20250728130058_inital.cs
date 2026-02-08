using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SunDaySchools.Migrations
{
    /// <inheritdoc />
    public partial class inital : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Classrooms",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    AgeOfChildren = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    NumberOfDisplineChildren = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Classrooms", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "SpiritualCurriculums",
                columns: table => new
                {
                    id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Kind = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Price = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    NummberOfLessons = table.Column<int>(type: "int", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Exist = table.Column<bool>(type: "bit", nullable: false),
                    Place = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    NumberOfAvailableTeacherBooks = table.Column<int>(type: "int", nullable: false),
                    NumberOfAvailableStudentBooks = table.Column<int>(type: "int", nullable: false),
                    TokeBefore = table.Column<bool>(type: "bit", nullable: false),
                    DateOfLastUse = table.Column<DateOnly>(type: "date", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SpiritualCurriculums", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "Tools",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Kind = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Place = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Quantity = table.Column<int>(type: "int", nullable: false),
                    IsAvailable = table.Column<bool>(type: "bit", nullable: false),
                    DateOfLastUse = table.Column<DateOnly>(type: "date", nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Tools", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Children",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Address = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    DateOfBirth = table.Column<DateOnly>(type: "date", nullable: false),
                    JoiningDate = table.Column<DateOnly>(type: "date", nullable: false),
                    LastAttendanceDate = table.Column<DateOnly>(type: "date", nullable: false),
                    SpiritualDateOFBirth = table.Column<DateOnly>(type: "date", nullable: false),
                    IsDisciplineChild = table.Column<bool>(type: "bit", nullable: false),
                    TotalNumberOfDaysAttended = table.Column<int>(type: "int", nullable: false),
                    HaveBrothers = table.Column<bool>(type: "bit", nullable: false),
                    BrothersNames = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ClassroomId = table.Column<int>(type: "int", nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Children", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Children_Classrooms_ClassroomId",
                        column: x => x.ClassroomId,
                        principalTable: "Classrooms",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Servants",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    JoiningDate = table.Column<DateOnly>(type: "date", nullable: false),
                    PhoneNumber = table.Column<long>(type: "bigint", nullable: false),
                    ClassroomId = table.Column<int>(type: "int", nullable: false),
                    SpiritualCurriculumid = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Servants", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Servants_Classrooms_ClassroomId",
                        column: x => x.ClassroomId,
                        principalTable: "Classrooms",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Servants_SpiritualCurriculums_SpiritualCurriculumid",
                        column: x => x.SpiritualCurriculumid,
                        principalTable: "SpiritualCurriculums",
                        principalColumn: "id");
                });

            migrationBuilder.CreateTable(
                name: "ChildContact",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Relation = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PhoneNumber = table.Column<int>(type: "int", nullable: false),
                    ChildId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChildContact", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ChildContact_Children_ChildId",
                        column: x => x.ChildId,
                        principalTable: "Children",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_ChildContact_ChildId",
                table: "ChildContact",
                column: "ChildId");

            migrationBuilder.CreateIndex(
                name: "IX_Children_ClassroomId",
                table: "Children",
                column: "ClassroomId");

            migrationBuilder.CreateIndex(
                name: "IX_Servants_ClassroomId",
                table: "Servants",
                column: "ClassroomId");

            migrationBuilder.CreateIndex(
                name: "IX_Servants_SpiritualCurriculumid",
                table: "Servants",
                column: "SpiritualCurriculumid");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ChildContact");

            migrationBuilder.DropTable(
                name: "Servants");

            migrationBuilder.DropTable(
                name: "Tools");

            migrationBuilder.DropTable(
                name: "Children");

            migrationBuilder.DropTable(
                name: "SpiritualCurriculums");

            migrationBuilder.DropTable(
                name: "Classrooms");
        }
    }
}
