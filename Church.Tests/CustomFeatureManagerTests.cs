using Church.BLL.Abstractions;
using Church.BLL.DTOS.CustomFeatures;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Implementations;
using Church.BLL.Services.CustomFeatures;
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

    [Fact]
    public async Task CreateFeature_rejects_empty_duplicate_and_invalid_names()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateFeatureAsync(new CustomFeatureCreateDto { DisplayName = "  " }));

        await manager.CreateFeatureAsync(new CustomFeatureCreateDto
        {
            DisplayName = "Inventory",
            Name = "inventory"
        });

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateFeatureAsync(new CustomFeatureCreateDto
            {
                DisplayName = "Inventory 2",
                Name = "inventory"
            }));

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateFeatureAsync(new CustomFeatureCreateDto
            {
                DisplayName = "Bad",
                Name = "1bad"
            }));
    }

    [Fact]
    public async Task Update_deactivate_and_list_features()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var created = await manager.CreateFeatureAsync(new CustomFeatureCreateDto
        {
            DisplayName = "Transport"
        });
        await manager.CreateFeatureAsync(new CustomFeatureCreateDto
        {
            DisplayName = "Inventory"
        });

        var updated = await manager.UpdateFeatureAsync(created.Id, new CustomFeatureUpdateDto
        {
            DisplayName = "Transport Updated",
            DisplayNameAr = "النقل",
            IsActive = false
        });
        Assert.Equal("Transport Updated", updated.DisplayName);
        Assert.False(updated.IsActive);

        Assert.Single(await manager.GetFeaturesAsync());
        Assert.Equal(2, (await manager.GetFeaturesAsync(includeInactive: true)).Count);

        await manager.UpdateFeatureAsync(created.Id, new CustomFeatureUpdateDto
        {
            DisplayName = "Transport Updated",
            IsActive = true
        });
        Assert.Equal(2, (await manager.GetFeaturesAsync()).Count);
    }

    [Fact]
    public async Task Max_features_per_church_enforced()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        for (var i = 0; i < CustomFeatureManager.MaxFeaturesPerChurch; i++)
        {
            await manager.CreateFeatureAsync(new CustomFeatureCreateDto
            {
                DisplayName = $"Feature {i}",
                Name = $"feature_{i}"
            });
        }

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateFeatureAsync(new CustomFeatureCreateDto
            {
                DisplayName = "Overflow",
                Name = "feature_overflow"
            }));
    }

    [Fact]
    public async Task Entity_field_record_lifecycle_and_validations()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var feature = await manager.CreateFeatureAsync(new CustomFeatureCreateDto
        {
            DisplayName = "Fleet"
        });
        var entity = await manager.CreateEntityAsync(feature.Id, new CustomEntityCreateDto
        {
            DisplayName = "Bus",
            PluralDisplayName = "Buses"
        });

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateFieldAsync(entity.Id, new CustomEntityFieldCreateDto
            {
                DisplayName = "Status",
                FieldType = CustomEntityFieldType.Dropdown
            }));

        var number = await manager.CreateFieldAsync(entity.Id, new CustomEntityFieldCreateDto
        {
            DisplayName = "Number",
            FieldType = CustomEntityFieldType.Text,
            IsRequired = true,
            IsUnique = true,
            IsSearchable = true,
            ShowOnList = true,
            ShowOnForm = true,
            ShowOnDetails = true
        });
        await manager.CreateFieldAsync(entity.Id, new CustomEntityFieldCreateDto
        {
            DisplayName = "Status",
            FieldType = CustomEntityFieldType.Dropdown,
            Options = new List<CustomEntityFieldOptionDto>
            {
                new() { Value = "active", DisplayText = "Active" },
                new() { Value = "down", DisplayText = "Down" }
            }
        });

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateFieldAsync(entity.Id, new CustomEntityFieldCreateDto
            {
                DisplayName = "Number Copy",
                Name = number.Name,
                FieldType = CustomEntityFieldType.Text
            }));

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateRecordAsync(entity.Id, new CustomEntityRecordWriteDto()));

        var record = await manager.CreateRecordAsync(entity.Id, new CustomEntityRecordWriteDto
        {
            Values = new Dictionary<string, object?>
            {
                ["number"] = "الاسم",
                ["status"] = "active"
            }
        });
        Assert.Equal("الاسم", record.Values["number"]?.ToString());

        var updated = await manager.UpdateRecordAsync(entity.Id, record.Id, new CustomEntityRecordWriteDto
        {
            Values = new Dictionary<string, object?>
            {
                ["number"] = "02",
                ["status"] = "down"
            }
        });
        Assert.Equal("02", updated.Values["number"]?.ToString());
        Assert.NotNull(updated.UpdatedAt);

        var page = await manager.GetRecordsAsync(entity.Id, search: "02", sort: null, descending: true, page: 1, pageSize: 20);
        Assert.Equal(1, page.Total);
        Assert.Single(page.Items);

        await manager.DeleteRecordAsync(entity.Id, record.Id);
        Assert.Null(await manager.GetRecordByIdAsync(entity.Id, record.Id));
    }

    [Fact]
    public async Task Entity_reference_same_feature_and_cross_feature_rules()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var featureA = await manager.CreateFeatureAsync(new CustomFeatureCreateDto { DisplayName = "A" });
        var featureB = await manager.CreateFeatureAsync(new CustomFeatureCreateDto { DisplayName = "B" });
        var route = await manager.CreateEntityAsync(featureA.Id, new CustomEntityCreateDto { DisplayName = "Route" });
        var stop = await manager.CreateEntityAsync(featureA.Id, new CustomEntityCreateDto { DisplayName = "Stop" });
        var other = await manager.CreateEntityAsync(featureB.Id, new CustomEntityCreateDto { DisplayName = "Other" });

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateFieldAsync(stop.Id, new CustomEntityFieldCreateDto
            {
                DisplayName = "Route",
                FieldType = CustomEntityFieldType.EntityReference,
                TargetEntityId = other.Id
            }));

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateFieldAsync(stop.Id, new CustomEntityFieldCreateDto
            {
                DisplayName = "Code",
                FieldType = CustomEntityFieldType.Text,
                TargetEntityId = route.Id
            }));

        await manager.CreateFieldAsync(route.Id, new CustomEntityFieldCreateDto
        {
            DisplayName = "Name",
            FieldType = CustomEntityFieldType.Text,
            IsRequired = true
        });
        var routeRecord = await manager.CreateRecordAsync(route.Id, new CustomEntityRecordWriteDto
        {
            Values = new Dictionary<string, object?> { ["name"] = "R1" }
        });

        await manager.CreateFieldAsync(stop.Id, new CustomEntityFieldCreateDto
        {
            DisplayName = "Route",
            FieldType = CustomEntityFieldType.EntityReference,
            TargetEntityId = route.Id,
            IsRequired = true
        });

        var stopRecord = await manager.CreateRecordAsync(stop.Id, new CustomEntityRecordWriteDto
        {
            Values = new Dictionary<string, object?> { ["route"] = routeRecord.Id }
        });
        Assert.Equal(routeRecord.Id, Convert.ToInt32(stopRecord.Values["route"]));

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateRecordAsync(stop.Id, new CustomEntityRecordWriteDto
            {
                Values = new Dictionary<string, object?> { ["route"] = new[] { routeRecord.Id, routeRecord.Id + 1 } }
            }));
    }

    [Fact]
    public async Task Delete_referenced_record_clears_incoming_references()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var feature = await manager.CreateFeatureAsync(new CustomFeatureCreateDto { DisplayName = "Links" });
        var parent = await manager.CreateEntityAsync(feature.Id, new CustomEntityCreateDto { DisplayName = "Parent" });
        var child = await manager.CreateEntityAsync(feature.Id, new CustomEntityCreateDto { DisplayName = "Child" });
        await manager.CreateFieldAsync(parent.Id, new CustomEntityFieldCreateDto
        {
            DisplayName = "Name",
            FieldType = CustomEntityFieldType.Text,
            IsRequired = true
        });
        var parentRecord = await manager.CreateRecordAsync(parent.Id, new CustomEntityRecordWriteDto
        {
            Values = new Dictionary<string, object?> { ["name"] = "P" }
        });
        await manager.CreateFieldAsync(child.Id, new CustomEntityFieldCreateDto
        {
            DisplayName = "Parent",
            FieldType = CustomEntityFieldType.EntityReference,
            TargetEntityId = parent.Id,
            IsRequired = true
        });
        await manager.CreateRecordAsync(child.Id, new CustomEntityRecordWriteDto
        {
            Values = new Dictionary<string, object?> { ["parent"] = parentRecord.Id }
        });

        await manager.DeleteRecordAsync(parent.Id, parentRecord.Id);

        Assert.Null(await manager.GetRecordByIdAsync(parent.Id, parentRecord.Id));
        Assert.Empty(await db.CustomEntityRecordReferences.ToListAsync());
    }

    [Fact]
    public async Task Permissions_can_grant_servant_create_and_inactive_feature_blocks_records()
    {
        var (connection, db, _, user, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var feature = await manager.CreateFeatureAsync(new CustomFeatureCreateDto { DisplayName = "Access" });
        var entity = await manager.CreateEntityAsync(feature.Id, new CustomEntityCreateDto { DisplayName = "Item" });
        await manager.CreateFieldAsync(entity.Id, new CustomEntityFieldCreateDto
        {
            DisplayName = "Title",
            FieldType = CustomEntityFieldType.Text,
            IsRequired = true
        });

        await manager.UpdatePermissionsAsync(entity.Id, new List<CustomEntityPermissionDto>
        {
            new()
            {
                RoleName = "SuperAdmin",
                CanCreate = true,
                CanRead = true,
                CanUpdate = true,
                CanDelete = true
            },
            new()
            {
                RoleName = "Admin",
                CanCreate = true,
                CanRead = true,
                CanUpdate = true,
                CanDelete = true
            },
            new()
            {
                RoleName = "Servant",
                CanCreate = true,
                CanRead = true,
                CanUpdate = false,
                CanDelete = false
            }
        });

        user.Setup(u => u.IsInRole("SuperAdmin")).Returns(false);
        user.Setup(u => u.IsInRole("Servant")).Returns(true);

        var created = await manager.CreateRecordAsync(entity.Id, new CustomEntityRecordWriteDto
        {
            Values = new Dictionary<string, object?> { ["title"] = "ok" }
        });
        Assert.True(created.Id > 0);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            manager.UpdateRecordAsync(entity.Id, created.Id, new CustomEntityRecordWriteDto
            {
                Values = new Dictionary<string, object?> { ["title"] = "nope" }
            }));

        user.Setup(u => u.IsInRole("SuperAdmin")).Returns(true);
        user.Setup(u => u.IsInRole("Servant")).Returns(false);
        await manager.UpdateFeatureAsync(feature.Id, new CustomFeatureUpdateDto
        {
            DisplayName = "Access",
            IsActive = false
        });

        await Assert.ThrowsAsync<NotFoundException>(() =>
            manager.CreateRecordAsync(entity.Id, new CustomEntityRecordWriteDto
            {
                Values = new Dictionary<string, object?> { ["title"] = "blocked" }
            }));
    }

    [Fact]
    public async Task Admin_feature_is_meeting_scoped_and_payload_cap_enforced()
    {
        var (connection, db, tenant, user, _) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        tenant.MeetingId = 1;
        user.Setup(u => u.IsInRole("SuperAdmin")).Returns(false);
        user.Setup(u => u.IsInRole("Admin")).Returns(true);

        var manager = new CustomFeatureManager(new CustomFeatureRepository(db), tenant, user.Object);
        var feature = await manager.CreateFeatureAsync(new CustomFeatureCreateDto
        {
            DisplayName = "Meeting Gear"
        });
        Assert.Equal(1, feature.MeetingId);

        var entity = await manager.CreateEntityAsync(feature.Id, new CustomEntityCreateDto
        {
            DisplayName = "Bag"
        });
        await manager.CreateFieldAsync(entity.Id, new CustomEntityFieldCreateDto
        {
            DisplayName = "Blob",
            FieldType = CustomEntityFieldType.LongText,
            IsRequired = true
        });

        var huge = new string('x', CustomEntityRecordValidator.MaxJsonBytes + 1000);
        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateRecordAsync(entity.Id, new CustomEntityRecordWriteDto
            {
                Values = new Dictionary<string, object?> { ["blob"] = huge }
            }));
    }

    [Fact]
    public async Task PageSize_over_100_is_clamped_and_sql_text_is_stored()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var feature = await manager.CreateFeatureAsync(new CustomFeatureCreateDto { DisplayName = "Bulk" });
        var entity = await manager.CreateEntityAsync(feature.Id, new CustomEntityCreateDto { DisplayName = "Row" });
        await manager.CreateFieldAsync(entity.Id, new CustomEntityFieldCreateDto
        {
            DisplayName = "Code",
            FieldType = CustomEntityFieldType.Text,
            IsRequired = true,
            IsSearchable = true
        });

        for (var i = 0; i < 5; i++)
        {
            await manager.CreateRecordAsync(entity.Id, new CustomEntityRecordWriteDto
            {
                Values = new Dictionary<string, object?> { ["code"] = $"C{i}" }
            });
        }

        var evil = "'; DROP TABLE CustomEntityRecords;--";
        await manager.CreateRecordAsync(entity.Id, new CustomEntityRecordWriteDto
        {
            Values = new Dictionary<string, object?> { ["code"] = evil }
        });

        var page = await manager.GetRecordsAsync(entity.Id, null, null, true, page: 1, pageSize: 500);
        Assert.Equal(20, page.PageSize);
        Assert.Equal(6, page.Total);
        Assert.Contains(page.Items, r => r.Values["code"]?.ToString() == evil);
        Assert.NotEmpty(await db.CustomEntityRecords.ToListAsync());
    }

    [Fact]
    public async Task ChurchA_cannot_read_ChurchB_records()
    {
        var (connection, db, tenant, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var feature = await manager.CreateFeatureAsync(new CustomFeatureCreateDto { DisplayName = "Private" });
        var entity = await manager.CreateEntityAsync(feature.Id, new CustomEntityCreateDto { DisplayName = "Secret" });
        await manager.CreateFieldAsync(entity.Id, new CustomEntityFieldCreateDto
        {
            DisplayName = "Code",
            FieldType = CustomEntityFieldType.Text,
            IsRequired = true
        });
        var record = await manager.CreateRecordAsync(entity.Id, new CustomEntityRecordWriteDto
        {
            Values = new Dictionary<string, object?> { ["code"] = "X" }
        });

        tenant.ChurchId = 2;
        tenant.MeetingId = null;
        tenant.Scope = TenantScopes.Church;

        await Assert.ThrowsAsync<NotFoundException>(() =>
            manager.GetRecordsAsync(entity.Id, null, null, true, 1, 20));
        Assert.Null(await manager.GetRecordByIdAsync(entity.Id, record.Id));
    }
}
