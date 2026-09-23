using Church.BLL.Abstractions;
using Church.BLL.DTOS.CustomFeatures;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Implementations;
using Church.DAL.Abstractions;
using Church.DAL.DBcontext;
using Church.DAL.Models;
using Church.DAL.Models.CustomFeatures;
using Church.DAL.Repository.Implementations;
using Church.Domain;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Moq;

namespace Church.Tests;

public sealed class CustomFeatureManagerTests
{
    private static async Task<(
        SqliteConnection Connection,
        ProgramContext Db,
        TenantContextState Tenant,
        Mock<ICurrentUserContext> User,
        CustomFeatureManager Manager)> CreateAsync()
    {
        var connection = new SqliteConnection("Data Source=:memory:");
        await connection.OpenAsync();

        var tenant = new TenantContextState
        {
            ChurchId = 1,
            MeetingId = null,
            Scope = TenantScopes.Church
        };

        var options = new DbContextOptionsBuilder<ProgramContext>()
            .UseSqlite(connection)
            .Options;
        var db = new ProgramContext(options, tenant);
        await db.Database.EnsureCreatedAsync();

        db.Churches.AddRange(
            new Church.DAL.Models.Church { Id = 1, Name = "A", PublicId = "church-a-00001" },
            new Church.DAL.Models.Church { Id = 2, Name = "B", PublicId = "church-b-00002" });
        db.Meetings.AddRange(
            new Meeting { Id = 1, Name = "M1", ChurchId = 1, PublicId = "meet-1-00000001" },
            new Meeting { Id = 2, Name = "M2", ChurchId = 2, PublicId = "meet-2-00000002" });
        db.Members.AddRange(
            new Member
            {
                Id = 10,
                Name1 = "John",
                ChurchId = 1,
                MeetingId = 1,
                DateOfBirth = new DateOnly(2010, 1, 1),
                JoiningDate = new DateOnly(2020, 1, 1),
                LastAttendanceDate = new DateOnly(2020, 1, 1)
            },
            new Member
            {
                Id = 20,
                Name1 = "Other",
                ChurchId = 2,
                MeetingId = 2,
                DateOfBirth = new DateOnly(2010, 1, 1),
                JoiningDate = new DateOnly(2020, 1, 1),
                LastAttendanceDate = new DateOnly(2020, 1, 1)
            });
        await db.SaveChangesAsync();

        var user = new Mock<ICurrentUserContext>();
        user.SetupGet(u => u.IsAuthenticated).Returns(true);
        user.SetupGet(u => u.UserId).Returns("user-1");
        user.Setup(u => u.IsInRole("SuperAdmin")).Returns(true);
        user.Setup(u => u.IsInRole("Admin")).Returns(false);
        user.Setup(u => u.IsInRole("Servant")).Returns(false);

        var manager = new CustomFeatureManager(new CustomFeatureRepository(db), tenant, user.Object);
        return (connection, db, tenant, user, manager);
    }

    [Fact]
    public async Task ChurchA_cannot_read_ChurchB_feature()
    {
        var (connection, db, tenant, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var created = await manager.CreateFeatureAsync(new CustomFeatureCreateDto
        {
            DisplayName = "Bus Management"
        });

        tenant.ChurchId = 2;
        tenant.MeetingId = null;
        tenant.Scope = TenantScopes.Church;

        Assert.Null(await manager.GetFeatureByIdAsync(created.Id));
        Assert.Empty(await manager.GetFeaturesAsync());
    }

    [Fact]
    public async Task CreateFeature_is_church_wide_for_super_admin()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var created = await manager.CreateFeatureAsync(new CustomFeatureCreateDto
        {
            DisplayName = "Bus Management",
            DisplayNameAr = "إدارة الأتوبيس"
        });

        Assert.True(created.IsActive);
        Assert.Null(created.MeetingId);
        Assert.Equal("bus_management", created.Name);
    }

    [Fact]
    public async Task Entity_gets_default_permissions_and_servant_cannot_create_records()
    {
        var (connection, db, _, user, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var feature = await manager.CreateFeatureAsync(new CustomFeatureCreateDto
        {
            DisplayName = "Inventory"
        });
        var entity = await manager.CreateEntityAsync(feature.Id, new CustomEntityCreateDto
        {
            DisplayName = "Item"
        });

        Assert.Contains(entity.Permissions, p => p.RoleName == "Servant" && p.CanRead && !p.CanCreate);

        user.Setup(u => u.IsInRole("SuperAdmin")).Returns(false);
        user.Setup(u => u.IsInRole("Servant")).Returns(true);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            manager.CreateRecordAsync(entity.Id, new CustomEntityRecordWriteDto()));
    }

    [Fact]
    public async Task Record_rejects_cross_tenant_member_reference()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var feature = await manager.CreateFeatureAsync(new CustomFeatureCreateDto
        {
            DisplayName = "Trips"
        });
        var entity = await manager.CreateEntityAsync(feature.Id, new CustomEntityCreateDto
        {
            DisplayName = "Trip"
        });
        await manager.CreateFieldAsync(entity.Id, new CustomEntityFieldCreateDto
        {
            DisplayName = "Member",
            FieldType = CustomEntityFieldType.MemberReference,
            IsRequired = true
        });

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateRecordAsync(entity.Id, new CustomEntityRecordWriteDto
            {
                Values = new Dictionary<string, object?> { ["member"] = 20 }
            }));
    }

    [Fact]
    public async Task Record_accepts_in_tenant_member_reference()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var feature = await manager.CreateFeatureAsync(new CustomFeatureCreateDto
        {
            DisplayName = "Trips"
        });
        var entity = await manager.CreateEntityAsync(feature.Id, new CustomEntityCreateDto
        {
            DisplayName = "Trip"
        });
        await manager.CreateFieldAsync(entity.Id, new CustomEntityFieldCreateDto
        {
            DisplayName = "Member",
            FieldType = CustomEntityFieldType.MemberReference,
            IsRequired = true
        });

        var record = await manager.CreateRecordAsync(entity.Id, new CustomEntityRecordWriteDto
        {
            Values = new Dictionary<string, object?> { ["member"] = 10 }
        });

        Assert.Equal(10, Convert.ToInt32(record.Values["member"]));
        Assert.Equal("John", record.Values["memberLabel"]?.ToString());
    }

    [Fact]
    public async Task DeleteFeature_cascades_records()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var feature = await manager.CreateFeatureAsync(new CustomFeatureCreateDto
        {
            DisplayName = "Gear"
        });
        var entity = await manager.CreateEntityAsync(feature.Id, new CustomEntityCreateDto
        {
            DisplayName = "Tool"
        });
        await manager.CreateFieldAsync(entity.Id, new CustomEntityFieldCreateDto
        {
            DisplayName = "Code",
            FieldType = CustomEntityFieldType.Text,
            IsRequired = true
        });
        await manager.CreateRecordAsync(entity.Id, new CustomEntityRecordWriteDto
        {
            Values = new Dictionary<string, object?> { ["code"] = "A1" }
        });

        await manager.DeleteFeatureAsync(feature.Id);

        Assert.Empty(db.CustomFeatures);
        Assert.Empty(db.CustomEntities);
        Assert.Empty(db.CustomEntityRecords);
    }

    [Fact]
    public async Task Unique_field_rejects_duplicate()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var feature = await manager.CreateFeatureAsync(new CustomFeatureCreateDto
        {
            DisplayName = "Buses"
        });
        var entity = await manager.CreateEntityAsync(feature.Id, new CustomEntityCreateDto
        {
            DisplayName = "Bus"
        });
        await manager.CreateFieldAsync(entity.Id, new CustomEntityFieldCreateDto
        {
            DisplayName = "Number",
            FieldType = CustomEntityFieldType.Text,
            IsRequired = true,
            IsUnique = true
        });

        await manager.CreateRecordAsync(entity.Id, new CustomEntityRecordWriteDto
        {
            Values = new Dictionary<string, object?> { ["number"] = "01" }
        });

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateRecordAsync(entity.Id, new CustomEntityRecordWriteDto
            {
                Values = new Dictionary<string, object?> { ["number"] = "01" }
            }));
    }

    [Fact]
    public async Task Servant_cannot_manage_metadata()
    {
        var (connection, db, _, user, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        user.Setup(u => u.IsInRole("SuperAdmin")).Returns(false);
        user.Setup(u => u.IsInRole("Servant")).Returns(true);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            manager.CreateFeatureAsync(new CustomFeatureCreateDto { DisplayName = "X" }));
    }
}
