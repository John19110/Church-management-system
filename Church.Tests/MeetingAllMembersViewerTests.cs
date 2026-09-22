using Church.DAL.Abstractions;
using Church.DAL.DBcontext;
using Church.DAL.Models;
using Church.Domain;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;

namespace Church.Tests;

public sealed class MeetingAllMembersViewerTests
{
    private static async Task<(SqliteConnection Connection, ProgramContext Db, TenantContextState Tenant)> CreateAsync()
    {
        var connection = new SqliteConnection("Data Source=:memory:");
        await connection.OpenAsync();

        var tenant = new TenantContextState
        {
            ChurchId = 1,
            MeetingId = 1,
            Scope = TenantScopes.Meeting,
            ClassroomIds = Array.Empty<int>()
        };

        var options = new DbContextOptionsBuilder<ProgramContext>()
            .UseSqlite(connection)
            .Options;

        var db = new ProgramContext(options, tenant);
        await db.Database.EnsureCreatedAsync();
        return (connection, db, tenant);
    }

    [Fact]
    public async Task Viewer_grant_is_meeting_specific()
    {
        var (connection, db, tenant) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        db.Churches.Add(new Church.DAL.Models.Church { Id = 1, Name = "A", PublicId = "church-a-00001" });
        db.Meetings.AddRange(
            new Meeting { Id = 1, Name = "M1", ChurchId = 1, PublicId = "meet-1-00000001", MemberViewMode = MemberViewMode.AllAndAssigned },
            new Meeting { Id = 2, Name = "M2", ChurchId = 1, PublicId = "meet-2-00000002", MemberViewMode = MemberViewMode.AllAndAssigned });

        // Minimal ApplicationUser row is not required when using IgnoreQueryFilters inserts with explicit FKs,
        // but Servant requires ApplicationUserId. Use a placeholder user.
        db.Users.Add(new ApplicationUser
        {
            Id = "u1",
            UserName = "s1",
            NormalizedUserName = "S1",
            ChurchId = 1,
            MeetingId = 1
        });
        db.Servants.Add(new Servant
        {
            Id = 10,
            ApplicationUserId = "u1",
            Name = "John",
            ChurchId = 1,
            MeetingId = 1
        });
        db.MeetingAllMembersViewers.Add(new MeetingAllMembersViewer
        {
            MeetingId = 1,
            ServantId = 10,
            ChurchId = 1
        });
        await db.SaveChangesAsync();

        tenant.ChurchId = 1;
        tenant.MeetingId = 1;

        Assert.True(await db.MeetingAllMembersViewers.AnyAsync(v =>
            v.MeetingId == 1 && v.ServantId == 10));
        Assert.False(await db.MeetingAllMembersViewers.AnyAsync(v =>
            v.MeetingId == 2 && v.ServantId == 10));
    }
}
