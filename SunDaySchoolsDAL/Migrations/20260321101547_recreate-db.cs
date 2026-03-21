using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace SunDaySchools.DAL.Migrations
{
    /// <inheritdoc />
    public partial class recreatedb : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AspNetRoles",
                columns: table => new
                {
                    Id = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    NormalizedName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    ConcurrencyStamp = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetRoles", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Churches",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Discriminator = table.Column<string>(type: "nvarchar(8)", maxLength: 8, nullable: false),
                    MeetingName = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ChurchId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Churches", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Churches_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "AspNetRoleClaims",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    RoleId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    ClaimType = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ClaimValue = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetRoleClaims", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AspNetRoleClaims_AspNetRoles_RoleId",
                        column: x => x.RoleId,
                        principalTable: "AspNetRoles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUsers",
                columns: table => new
                {
                    Id = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true),
                    IsApproved = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UserName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    NormalizedUserName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    Email = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    NormalizedEmail = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    EmailConfirmed = table.Column<bool>(type: "bit", nullable: false),
                    PasswordHash = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    SecurityStamp = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ConcurrencyStamp = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PhoneNumber = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PhoneNumberConfirmed = table.Column<bool>(type: "bit", nullable: false),
                    TwoFactorEnabled = table.Column<bool>(type: "bit", nullable: false),
                    LockoutEnd = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    LockoutEnabled = table.Column<bool>(type: "bit", nullable: false),
                    AccessFailedCount = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUsers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AspNetUsers_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_AspNetUsers_Churches_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Classrooms",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    AgeOfMembers = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    NumberOfDisplineMembers = table.Column<int>(type: "int", nullable: true),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Classrooms", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Classrooms_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Classrooms_Churches_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "SpiritualCurriculums",
                columns: table => new
                {
                    id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Kind = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Price = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    NummberOfLessons = table.Column<int>(type: "int", nullable: true),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Exist = table.Column<bool>(type: "bit", nullable: true),
                    Place = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    NumberOfAvailableTeacherBooks = table.Column<int>(type: "int", nullable: true),
                    NumberOfAvailableStudentBooks = table.Column<int>(type: "int", nullable: true),
                    TokeBefore = table.Column<bool>(type: "bit", nullable: true),
                    DateOfLastUse = table.Column<DateOnly>(type: "date", nullable: true),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SpiritualCurriculums", x => x.id);
                    table.ForeignKey(
                        name: "FK_SpiritualCurriculums_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_SpiritualCurriculums_Churches_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Tools",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Kind = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Place = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Quantity = table.Column<int>(type: "int", nullable: true),
                    IsAvailable = table.Column<bool>(type: "bit", nullable: true),
                    DateOfLastUse = table.Column<DateOnly>(type: "date", nullable: true),
                    Notes = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Tools", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Tools_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Tools_Churches_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "AspNetUserClaims",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    ClaimType = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ClaimValue = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUserClaims", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AspNetUserClaims_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUserLogins",
                columns: table => new
                {
                    LoginProvider = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    ProviderKey = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    ProviderDisplayName = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    UserId = table.Column<string>(type: "nvarchar(450)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUserLogins", x => new { x.LoginProvider, x.ProviderKey });
                    table.ForeignKey(
                        name: "FK_AspNetUserLogins_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUserRoles",
                columns: table => new
                {
                    UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    RoleId = table.Column<string>(type: "nvarchar(450)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUserRoles", x => new { x.UserId, x.RoleId });
                    table.ForeignKey(
                        name: "FK_AspNetUserRoles_AspNetRoles_RoleId",
                        column: x => x.RoleId,
                        principalTable: "AspNetRoles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_AspNetUserRoles_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AspNetUserTokens",
                columns: table => new
                {
                    UserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    LoginProvider = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    Value = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AspNetUserTokens", x => new { x.UserId, x.LoginProvider, x.Name });
                    table.ForeignKey(
                        name: "FK_AspNetUserTokens_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Exams",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ClassroomId = table.Column<int>(type: "int", nullable: true),
                    ExamDate = table.Column<DateOnly>(type: "date", nullable: false),
                    MaxScore = table.Column<int>(type: "int", nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Exams", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Exams_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Exams_Churches_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Exams_Classrooms_ClassroomId",
                        column: x => x.ClassroomId,
                        principalTable: "Classrooms",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "Members",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ImageFileName = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ImageUrl = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Name1 = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Name2 = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Name3 = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Gender = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Address = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    DateOfBirth = table.Column<DateOnly>(type: "date", nullable: false),
                    JoiningDate = table.Column<DateOnly>(type: "date", nullable: false),
                    LastAttendanceDate = table.Column<DateOnly>(type: "date", nullable: false),
                    SpiritualDateOfBirth = table.Column<DateOnly>(type: "date", nullable: true),
                    IsDisciplined = table.Column<bool>(type: "bit", nullable: false),
                    TotalNumberOfDaysAttended = table.Column<int>(type: "int", nullable: false),
                    HaveBrothers = table.Column<bool>(type: "bit", nullable: true),
                    BrothersNames = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ClassroomId = table.Column<int>(type: "int", nullable: true),
                    Notes = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Members", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Members_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Members_Churches_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Members_Classrooms_ClassroomId",
                        column: x => x.ClassroomId,
                        principalTable: "Classrooms",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Servants",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ApplicationUserId = table.Column<string>(type: "nvarchar(450)", nullable: false),
                    ImageFileName = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ImageUrl = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    BirthDate = table.Column<DateOnly>(type: "date", nullable: true),
                    JoiningDate = table.Column<DateOnly>(type: "date", nullable: true),
                    PhoneNumber = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    classroomsIds = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    SpiritualCurriculumid = table.Column<int>(type: "int", nullable: true),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Servants", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Servants_AspNetUsers_ApplicationUserId",
                        column: x => x.ApplicationUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_Servants_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Servants_Churches_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_Servants_SpiritualCurriculums_SpiritualCurriculumid",
                        column: x => x.SpiritualCurriculumid,
                        principalTable: "SpiritualCurriculums",
                        principalColumn: "id");
                });

            migrationBuilder.CreateTable(
                name: "ChildContacts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Relation = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    PhoneNumber = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ChildId = table.Column<int>(type: "int", nullable: false),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
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

            migrationBuilder.CreateTable(
                name: "ExamResults",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ExamId = table.Column<int>(type: "int", nullable: false),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    Score = table.Column<int>(type: "int", nullable: false),
                    IsAbsent = table.Column<bool>(type: "bit", nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ExamResults", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ExamResults_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_ExamResults_Churches_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_ExamResults_Exams_ExamId",
                        column: x => x.ExamId,
                        principalTable: "Exams",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ExamResults_Members_MemberId",
                        column: x => x.MemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AttendanceSessions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ClassroomId = table.Column<int>(type: "int", nullable: false),
                    TakenByServantId = table.Column<int>(type: "int", nullable: true),
                    Notes = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedAt = table.Column<DateOnly>(type: "date", nullable: false),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AttendanceSessions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AttendanceSessions_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_AttendanceSessions_Churches_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_AttendanceSessions_Classrooms_ClassroomId",
                        column: x => x.ClassroomId,
                        principalTable: "Classrooms",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_AttendanceSessions_Servants_TakenByServantId",
                        column: x => x.TakenByServantId,
                        principalTable: "Servants",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "ClassroomServant",
                columns: table => new
                {
                    ClassroomsId = table.Column<int>(type: "int", nullable: false),
                    ServantsId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ClassroomServant", x => new { x.ClassroomsId, x.ServantsId });
                    table.ForeignKey(
                        name: "FK_ClassroomServant_Classrooms_ClassroomsId",
                        column: x => x.ClassroomsId,
                        principalTable: "Classrooms",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ClassroomServant_Servants_ServantsId",
                        column: x => x.ServantsId,
                        principalTable: "Servants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "PhoneCalls",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ServantId = table.Column<int>(type: "int", nullable: true),
                    Notes = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ChildContactId = table.Column<int>(type: "int", nullable: true),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PhoneCalls", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PhoneCalls_ChildContacts_ChildContactId",
                        column: x => x.ChildContactId,
                        principalTable: "ChildContacts",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_PhoneCalls_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_PhoneCalls_Churches_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_PhoneCalls_Servants_ServantId",
                        column: x => x.ServantId,
                        principalTable: "Servants",
                        principalColumn: "Id");
                });

            migrationBuilder.CreateTable(
                name: "AttendanceRecords",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    AttendanceSessionId = table.Column<int>(type: "int", nullable: false),
                    MemberId = table.Column<int>(type: "int", nullable: false),
                    MadeHomeWork = table.Column<bool>(type: "bit", nullable: false),
                    HasTools = table.Column<bool>(type: "bit", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    Note = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ChurchId = table.Column<int>(type: "int", nullable: true),
                    MeetingId = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AttendanceRecords", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AttendanceRecords_AttendanceSessions_AttendanceSessionId",
                        column: x => x.AttendanceSessionId,
                        principalTable: "AttendanceSessions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_AttendanceRecords_Churches_ChurchId",
                        column: x => x.ChurchId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_AttendanceRecords_Churches_MeetingId",
                        column: x => x.MeetingId,
                        principalTable: "Churches",
                        principalColumn: "Id");
                    table.ForeignKey(
                        name: "FK_AttendanceRecords_Members_MemberId",
                        column: x => x.MemberId,
                        principalTable: "Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "Classrooms",
                columns: new[] { "Id", "AgeOfMembers", "ChurchId", "MeetingId", "Name", "NumberOfDisplineMembers" },
                values: new object[,]
                {
                    { 1, "حضانه و كيجي", null, null, "الوداعه", null },
                    { 2, "اولي و تانيه", null, null, "السلام", null },
                    { 3, "تالته ورابعه", null, null, "الأيمان", null },
                    { 4, "خامسه و سادسه", null, null, "المحبه", null }
                });

            migrationBuilder.CreateIndex(
                name: "IX_AspNetRoleClaims_RoleId",
                table: "AspNetRoleClaims",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "RoleNameIndex",
                table: "AspNetRoles",
                column: "NormalizedName",
                unique: true,
                filter: "[NormalizedName] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUserClaims_UserId",
                table: "AspNetUserClaims",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUserLogins_UserId",
                table: "AspNetUserLogins",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUserRoles_RoleId",
                table: "AspNetUserRoles",
                column: "RoleId");

            migrationBuilder.CreateIndex(
                name: "EmailIndex",
                table: "AspNetUsers",
                column: "NormalizedEmail");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUsers_ChurchId",
                table: "AspNetUsers",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_AspNetUsers_MeetingId",
                table: "AspNetUsers",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "UserNameIndex",
                table: "AspNetUsers",
                column: "NormalizedUserName",
                unique: true,
                filter: "[NormalizedUserName] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceRecords_AttendanceSessionId_MemberId",
                table: "AttendanceRecords",
                columns: new[] { "AttendanceSessionId", "MemberId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceRecords_ChurchId",
                table: "AttendanceRecords",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceRecords_MeetingId",
                table: "AttendanceRecords",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceRecords_MemberId",
                table: "AttendanceRecords",
                column: "MemberId");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceSessions_ChurchId",
                table: "AttendanceSessions",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceSessions_ClassroomId",
                table: "AttendanceSessions",
                column: "ClassroomId");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceSessions_MeetingId",
                table: "AttendanceSessions",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_AttendanceSessions_TakenByServantId",
                table: "AttendanceSessions",
                column: "TakenByServantId");

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

            migrationBuilder.CreateIndex(
                name: "IX_Churches_ChurchId",
                table: "Churches",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_Classrooms_ChurchId",
                table: "Classrooms",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_Classrooms_MeetingId",
                table: "Classrooms",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_ClassroomServant_ServantsId",
                table: "ClassroomServant",
                column: "ServantsId");

            migrationBuilder.CreateIndex(
                name: "IX_ExamResults_ChurchId",
                table: "ExamResults",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_ExamResults_ExamId",
                table: "ExamResults",
                column: "ExamId");

            migrationBuilder.CreateIndex(
                name: "IX_ExamResults_MeetingId",
                table: "ExamResults",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_ExamResults_MemberId",
                table: "ExamResults",
                column: "MemberId");

            migrationBuilder.CreateIndex(
                name: "IX_Exams_ChurchId",
                table: "Exams",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_Exams_ClassroomId",
                table: "Exams",
                column: "ClassroomId");

            migrationBuilder.CreateIndex(
                name: "IX_Exams_MeetingId",
                table: "Exams",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_Members_ChurchId",
                table: "Members",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_Members_ClassroomId",
                table: "Members",
                column: "ClassroomId");

            migrationBuilder.CreateIndex(
                name: "IX_Members_MeetingId",
                table: "Members",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_PhoneCalls_ChildContactId",
                table: "PhoneCalls",
                column: "ChildContactId");

            migrationBuilder.CreateIndex(
                name: "IX_PhoneCalls_ChurchId",
                table: "PhoneCalls",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_PhoneCalls_MeetingId",
                table: "PhoneCalls",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_PhoneCalls_ServantId",
                table: "PhoneCalls",
                column: "ServantId");

            migrationBuilder.CreateIndex(
                name: "IX_Servants_ApplicationUserId",
                table: "Servants",
                column: "ApplicationUserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Servants_ChurchId",
                table: "Servants",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_Servants_MeetingId",
                table: "Servants",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_Servants_SpiritualCurriculumid",
                table: "Servants",
                column: "SpiritualCurriculumid");

            migrationBuilder.CreateIndex(
                name: "IX_SpiritualCurriculums_ChurchId",
                table: "SpiritualCurriculums",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_SpiritualCurriculums_MeetingId",
                table: "SpiritualCurriculums",
                column: "MeetingId");

            migrationBuilder.CreateIndex(
                name: "IX_Tools_ChurchId",
                table: "Tools",
                column: "ChurchId");

            migrationBuilder.CreateIndex(
                name: "IX_Tools_MeetingId",
                table: "Tools",
                column: "MeetingId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AspNetRoleClaims");

            migrationBuilder.DropTable(
                name: "AspNetUserClaims");

            migrationBuilder.DropTable(
                name: "AspNetUserLogins");

            migrationBuilder.DropTable(
                name: "AspNetUserRoles");

            migrationBuilder.DropTable(
                name: "AspNetUserTokens");

            migrationBuilder.DropTable(
                name: "AttendanceRecords");

            migrationBuilder.DropTable(
                name: "ClassroomServant");

            migrationBuilder.DropTable(
                name: "ExamResults");

            migrationBuilder.DropTable(
                name: "PhoneCalls");

            migrationBuilder.DropTable(
                name: "Tools");

            migrationBuilder.DropTable(
                name: "AspNetRoles");

            migrationBuilder.DropTable(
                name: "AttendanceSessions");

            migrationBuilder.DropTable(
                name: "Exams");

            migrationBuilder.DropTable(
                name: "ChildContacts");

            migrationBuilder.DropTable(
                name: "Servants");

            migrationBuilder.DropTable(
                name: "Members");

            migrationBuilder.DropTable(
                name: "AspNetUsers");

            migrationBuilder.DropTable(
                name: "SpiritualCurriculums");

            migrationBuilder.DropTable(
                name: "Classrooms");

            migrationBuilder.DropTable(
                name: "Churches");
        }
    }
}
