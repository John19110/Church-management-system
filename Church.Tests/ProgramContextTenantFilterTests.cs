using Church.DAL.Abstractions;
using Church.DAL.DBcontext;
using Church.DAL.Models;
using Church.Domain;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;

namespace Church.Tests;

public sealed class ProgramContextTenantFilterTests
{
    private static async Task<(SqliteConnection Connection, ProgramContext Db)> CreateAsync(
        TenantContextState tenant)
    {
        var connection = new SqliteConnection("Data Source=:memory:");
        await connection.OpenAsync();

        var options = new DbContextOptionsBuilder<ProgramContext>()
            .UseSqlite(connection)
            .Options;

        var db = new ProgramContext(options, tenant);
        await db.Database.EnsureCreatedAsync();
        return (connection, db);
    }

    private static async Task SeedChurchesAndMeetingsAsync(ProgramContext db)
    {
        db.Churches.AddRange(
            new Church.DAL.Models.Church { Id = 1, Name = "A", PublicId = "church-a-00001" },
            new Church.DAL.Models.Church { Id = 2, Name = "B", PublicId = "church-b-00002" },
            new Church.DAL.Models.Church { Id = 7, Name = "Seven", PublicId = "church-7-00007" });
        db.Meetings.AddRange(
            new Meeting { Id = 1, Name = "M1", ChurchId = 1, PublicId = "meet-1-00000001" },
            new Meeting { Id = 2, Name = "M2", ChurchId = 1, PublicId = "meet-2-00000002" },
            new Meeting { Id = 3, Name = "M3", ChurchId = 7, PublicId = "meet-3-00000003" },
            new Meeting { Id = 4, Name = "M4", ChurchId = 2, PublicId = "meet-4-00000004" });
        await db.SaveChangesAsync();
    }

    [Fact]
    public async Task ChurchA_cannot_query_ChurchB_data()
    {
        var tenant = new TenantContextState { ChurchId = 1 };
        var (connection, db) = await CreateAsync(tenant);
        await using var _ = connection;
        await using var __ = db;

        await SeedChurchesAndMeetingsAsync(db);

        db.Members.Add(new Member
        {
            Id = 10,
            Name1 = "FromA",
            ChurchId = 1,
            MeetingId = 1,
            DateOfBirth = new DateOnly(2010, 1, 1),
            JoiningDate = new DateOnly(2020, 1, 1),
            LastAttendanceDate = new DateOnly(2020, 1, 1)
        });
        db.Members.Add(new Member
        {
            Id = 20,
            Name1 = "FromB",
            ChurchId = 2,
            MeetingId = 4,
            DateOfBirth = new DateOnly(2010, 1, 1),
            JoiningDate = new DateOnly(2020, 1, 1),
            LastAttendanceDate = new DateOnly(2020, 1, 1)
        });
        await db.SaveChangesAsync();

        tenant.ChurchId = 1;
        tenant.MeetingId = null;
        tenant.Scope = TenantScopes.Church;
        tenant.ClassroomIds = Array.Empty<int>();

        var names = await db.Members.Select(m => m.Name1).ToListAsync();
        Assert.Single(names);
        Assert.Equal("FromA", names[0]);
        Assert.Null(await db.Members.FirstOrDefaultAsync(m => m.Name1 == "FromB"));
    }

    [Fact]
    public async Task No_tenant_context_returns_no_churches()
    {
        var tenant = new TenantContextState { ChurchId = 1 };
        var (connection, db) = await CreateAsync(tenant);
        await using var _ = connection;
        await using var __ = db;

        db.Churches.Add(new Church.DAL.Models.Church { Id = 1, Name = "A", PublicId = "church-a-00001" });
        await db.SaveChangesAsync();

        tenant.ChurchId = null;
        tenant.MeetingId = null;
        tenant.Scope = null;

        Assert.Empty(await db.Churches.ToListAsync());
        Assert.Single(await db.Churches.IgnoreQueryFilters().ToListAsync());
    }

    [Fact]
    public async Task New_entity_receives_ChurchId_from_tenant_context()
    {
        var tenant = new TenantContextState
        {
            ChurchId = 7,
            MeetingId = 3,
            Scope = TenantScopes.Meeting,
            ClassroomIds = Array.Empty<int>()
        };
        var (connection, db) = await CreateAsync(tenant);
        await using var _ = connection;
        await using var __ = db;

        await SeedChurchesAndMeetingsAsync(db);

        var member = new Member
        {
            Name1 = "AutoTenant",
            DateOfBirth = new DateOnly(2010, 1, 1),
            JoiningDate = new DateOnly(2020, 1, 1),
            LastAttendanceDate = new DateOnly(2020, 1, 1)
        };
        db.Members.Add(member);
        await db.SaveChangesAsync();

        Assert.Equal(7, member.ChurchId);
        Assert.Equal(3, member.MeetingId);
    }

    [Fact]
    public async Task Meeting_scope_hides_other_meeting_members()
    {
        var tenant = new TenantContextState { ChurchId = 1 };
        var (connection, db) = await CreateAsync(tenant);
        await using var _ = connection;
        await using var __ = db;

        await SeedChurchesAndMeetingsAsync(db);

        db.Members.Add(new Member
        {
            Id = 1,
            Name1 = "M1",
            ChurchId = 1,
            MeetingId = 1,
            DateOfBirth = new DateOnly(2010, 1, 1),
            JoiningDate = new DateOnly(2020, 1, 1),
            LastAttendanceDate = new DateOnly(2020, 1, 1)
        });
        db.Members.Add(new Member
        {
            Id = 2,
            Name1 = "M2",
            ChurchId = 1,
            MeetingId = 2,
            DateOfBirth = new DateOnly(2010, 1, 1),
            JoiningDate = new DateOnly(2020, 1, 1),
            LastAttendanceDate = new DateOnly(2020, 1, 1)
        });
        await db.SaveChangesAsync();

        tenant.ChurchId = 1;
        tenant.MeetingId = 1;
        tenant.Scope = TenantScopes.Meeting;
        tenant.ClassroomIds = Array.Empty<int>();

        var names = await db.Members.Select(m => m.Name1).ToListAsync();
        Assert.Single(names);
        Assert.Equal("M1", names[0]);
    }
}
