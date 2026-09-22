using Church.DAL.Abstractions;
using Church.DAL.DBcontext;
using Church.DAL.Models;
using Church.Domain;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;

namespace Church.Tests;

public sealed class MemberViewModeQueryTests
{
    private static async Task<(SqliteConnection Connection, ProgramContext Db, TenantContextState Tenant)> CreateAsync()
    {
        var connection = new SqliteConnection("Data Source=:memory:");
        await connection.OpenAsync();

        var tenant = new TenantContextState
        {
            ChurchId = 1,
            MeetingId = 1,
            Scope = TenantScopes.Classroom,
            ClassroomIds = new[] { 10 }
        };

        var options = new DbContextOptionsBuilder<ProgramContext>()
            .UseSqlite(connection)
            .Options;

        var db = new ProgramContext(options, tenant);
        await db.Database.EnsureCreatedAsync();
        return (connection, db, tenant);
    }

    private static async Task SeedAsync(ProgramContext db)
    {
        db.Churches.Add(new Church.DAL.Models.Church { Id = 1, Name = "A", PublicId = "church-a-00001" });
        db.Churches.Add(new Church.DAL.Models.Church { Id = 2, Name = "B", PublicId = "church-b-00002" });
        db.Meetings.Add(new Meeting
        {
            Id = 1,
            Name = "Sunday",
            ChurchId = 1,
            PublicId = "meet-1-00000001",
            HasClassrooms = true,
            MemberViewMode = MemberViewMode.AllAndAssigned
        });
        db.Meetings.Add(new Meeting
        {
            Id = 2,
            Name = "Other",
            ChurchId = 1,
            PublicId = "meet-2-00000002",
            HasClassrooms = true,
            MemberViewMode = MemberViewMode.AssignedOnly
        });
        db.Meetings.Add(new Meeting
        {
            Id = 3,
            Name = "ChurchB",
            ChurchId = 2,
            PublicId = "meet-3-00000003",
            HasClassrooms = true,
            MemberViewMode = MemberViewMode.AllAndAssigned
        });

        db.Classrooms.Add(new Classroom
        {
            Id = 10,
            Name = "Group A",
            ChurchId = 1,
            MeetingId = 1
        });
        db.Classrooms.Add(new Classroom
        {
            Id = 20,
            Name = "Group B",
            ChurchId = 1,
            MeetingId = 1
        });

        db.Members.Add(new Member
        {
            Id = 100,
            Name1 = "Alice",
            ChurchId = 1,
            MeetingId = 1,
            ClassroomId = 10,
            DateOfBirth = new DateOnly(2010, 1, 1),
            JoiningDate = new DateOnly(2020, 1, 1),
            LastAttendanceDate = new DateOnly(2020, 1, 1)
        });
        db.Members.Add(new Member
        {
            Id = 200,
            Name1 = "Bob",
            ChurchId = 1,
            MeetingId = 1,
            ClassroomId = 20,
            DateOfBirth = new DateOnly(2010, 1, 1),
            JoiningDate = new DateOnly(2020, 1, 1),
            LastAttendanceDate = new DateOnly(2020, 1, 1)
        });
        db.Members.Add(new Member
        {
            Id = 300,
            Name1 = "OtherMeeting",
            ChurchId = 1,
            MeetingId = 2,
            ClassroomId = 10,
            DateOfBirth = new DateOnly(2010, 1, 1),
            JoiningDate = new DateOnly(2020, 1, 1),
            LastAttendanceDate = new DateOnly(2020, 1, 1)
        });
        db.Members.Add(new Member
        {
            Id = 400,
            Name1 = "OtherChurch",
            ChurchId = 2,
            MeetingId = 3,
            ClassroomId = 10,
            DateOfBirth = new DateOnly(2010, 1, 1),
            JoiningDate = new DateOnly(2020, 1, 1),
            LastAttendanceDate = new DateOnly(2020, 1, 1)
        });

        await db.SaveChangesAsync();
    }

    [Fact]
    public async Task Classroom_scope_sees_only_assigned_classroom_members()
    {
        var (connection, db, tenant) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;
        await SeedAsync(db);

        tenant.Scope = TenantScopes.Classroom;
        tenant.ClassroomIds = new[] { 10 };
        tenant.MeetingId = 1;
        tenant.ChurchId = 1;

        var names = await db.Members
            .Where(m => m.MeetingId == 1)
            .Select(m => m.Name1)
            .ToListAsync();

        Assert.Single(names);
        Assert.Equal("Alice", names[0]);
    }

    [Fact]
    public async Task IgnoreQueryFilters_all_meeting_respects_church_and_meeting()
    {
        var (connection, db, _) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;
        await SeedAsync(db);

        var names = await db.Members
            .IgnoreQueryFilters()
            .Where(m => m.ChurchId == 1 && m.MeetingId == 1)
            .Select(m => m.Name1)
            .OrderBy(n => n)
            .ToListAsync();

        Assert.Equal(new[] { "Alice", "Bob" }, names);
    }

    [Fact]
    public async Task IgnoreQueryFilters_cannot_leak_other_church_when_church_filter_applied()
    {
        var (connection, db, _) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;
        await SeedAsync(db);

        var leaked = await db.Members
            .IgnoreQueryFilters()
            .Where(m => m.ChurchId == 1 && m.MeetingId == 1 && m.Name1 == "OtherChurch")
            .AnyAsync();

        Assert.False(leaked);
    }

    [Fact]
    public async Task New_meeting_defaults_to_AssignedOnly()
    {
        var (connection, db, _) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        db.Churches.Add(new Church.DAL.Models.Church { Id = 1, Name = "A", PublicId = "church-a-00001" });
        db.Meetings.Add(new Meeting
        {
            Id = 9,
            Name = "Fresh",
            ChurchId = 1,
            PublicId = "meet-9-00000009"
        });
        await db.SaveChangesAsync();

        var meeting = await db.Meetings.IgnoreQueryFilters().SingleAsync(m => m.Id == 9);
        Assert.Equal(MemberViewMode.AssignedOnly, meeting.MemberViewMode);
    }
}
