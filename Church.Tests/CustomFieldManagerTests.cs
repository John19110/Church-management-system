using AutoMapper;
using Church.BLL.Abstractions;
using Church.BLL.AutoMapper;
using Church.BLL.DTOS.CustomFields;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Implementations;
using Church.BLL.Services.CustomFields;
using Church.DAL.Abstractions;
using Church.DAL.DBcontext;
using Church.DAL.Models;
using Church.DAL.Models.CustomFields;
using Church.DAL.Repository.Implementations;
using Church.Domain;
using Microsoft.AspNetCore.Identity;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Church.Tests;

public sealed class CustomFieldManagerTests
{
    private static async Task<(
        SqliteConnection Connection,
        ProgramContext Db,
        TenantContextState Tenant,
        Mock<ICurrentUserContext> User,
        CustomFieldManager Manager)> CreateAsync(string role = "Admin")
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
        user.Setup(u => u.IsInRole("SuperAdmin")).Returns(role == "SuperAdmin");
        user.Setup(u => u.IsInRole("Admin")).Returns(role == "Admin");
        user.Setup(u => u.IsInRole("Servant")).Returns(role == "Servant");

        var manager = CreateManager(db, tenant, user.Object);
        return (connection, db, tenant, user, manager);
    }

    private static CustomFieldDefinitionCreateDto CreateDto(
        string displayName,
        CustomFieldDataType dataType,
        string entityName = CustomFieldEntityNames.Member,
        Action<CustomFieldDefinitionCreateDto>? configure = null)
    {
        var dto = new CustomFieldDefinitionCreateDto
        {
            DisplayName = displayName,
            EntityName = entityName,
            DataType = dataType
        };
        configure?.Invoke(dto);
        return dto;
    }

    [Fact]
    public async Task CreateDefinition_text_field_stamps_tenant_and_generates_name()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var created = await manager.CreateDefinitionAsync(CreateDto(
            "Baptism Notes",
            CustomFieldDataType.Text,
            configure: d => d.DisplayNameAr = "ملاحظات المعمودية"));

        Assert.True(created.IsActive);
        Assert.Equal("baptism_notes", created.Name);
        Assert.Equal("ملاحظات المعمودية", created.DisplayNameAr);

        var row = await db.CustomFieldDefinitions.SingleAsync(d => d.Id == created.Id);
        Assert.Equal(1, row.ChurchId);
    }

    [Fact]
    public async Task CreateDefinition_supports_all_data_types()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var options = new List<CustomFieldOptionDto>
        {
            new() { Value = "A", DisplayText = "Alpha", SortOrder = 1 },
            new() { Value = "B", DisplayText = "Beta", SortOrder = 2 }
        };

        foreach (CustomFieldDataType type in Enum.GetValues<CustomFieldDataType>())
        {
            var created = await manager.CreateDefinitionAsync(CreateDto(
                $"Field {type}",
                type,
                configure: d =>
                {
                    if (type is CustomFieldDataType.SingleSelect or CustomFieldDataType.MultiSelect)
                        d.Options = options;
                }));
            Assert.Equal(type, created.DataType);
        }
    }

    [Fact]
    public async Task CreateDefinition_rejects_select_without_options()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateDefinitionAsync(CreateDto("Color", CustomFieldDataType.SingleSelect)));
    }

    [Fact]
    public async Task CreateDefinition_rejects_empty_display_name_and_reserved_name()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateDefinitionAsync(CreateDto("   ", CustomFieldDataType.Text)));

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateDefinitionAsync(CreateDto(
                "First",
                CustomFieldDataType.Text,
                configure: d => d.Name = "name1")));
    }

    [Fact]
    public async Task CreateDefinition_rejects_duplicate_and_invalid_names()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        await manager.CreateDefinitionAsync(CreateDto(
            "Extra",
            CustomFieldDataType.Text,
            configure: d => d.Name = "notes_extra"));

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateDefinitionAsync(CreateDto(
                "Extra 2",
                CustomFieldDataType.Text,
                configure: d => d.Name = "notes_extra")));

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateDefinitionAsync(CreateDto(
                "Bad",
                CustomFieldDataType.Text,
                configure: d => d.Name = "1bad-name!")));
    }

    [Fact]
    public async Task CreateDefinition_rejects_unsupported_entity_and_bad_default()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateDefinitionAsync(CreateDto(
                "X",
                CustomFieldDataType.Text,
                entityName: "Invoice")));

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.CreateDefinitionAsync(CreateDto(
                "Age",
                CustomFieldDataType.Number,
                configure: d => d.DefaultValue = "abc")));
    }

    [Fact]
    public async Task Servant_cannot_manage_definitions()
    {
        var (connection, db, _, _, manager) = await CreateAsync("Servant");
        await using var _ = connection;
        await using var __ = db;

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            manager.CreateDefinitionAsync(CreateDto("X", CustomFieldDataType.Text)));
    }

    [Fact]
    public async Task ChurchA_cannot_read_ChurchB_definition()
    {
        var (connection, db, tenant, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var created = await manager.CreateDefinitionAsync(CreateDto("Secret", CustomFieldDataType.Text));

        tenant.ChurchId = 2;
        tenant.MeetingId = null;
        tenant.Scope = TenantScopes.Church;

        Assert.Null(await manager.GetDefinitionByIdAsync(created.Id));
    }

    [Fact]
    public async Task Update_deactivate_activate_and_delete_user_field()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var created = await manager.CreateDefinitionAsync(CreateDto(
            "Hobby",
            CustomFieldDataType.Text,
            configure: d => d.DisplayNameAr = "هواية"));

        var updated = await manager.UpdateDefinitionAsync(created.Id, new CustomFieldDefinitionUpdateDto
        {
            DisplayName = "Hobby Updated",
            DisplayNameAr = "هواية محدثة",
            IsRequired = true
        });
        Assert.Equal("Hobby Updated", updated.DisplayName);
        Assert.True(updated.IsRequired);

        await manager.DeactivateDefinitionAsync(created.Id);
        var activeOnly = await manager.GetDefinitionsByEntityAsync(CustomFieldEntityNames.Member);
        Assert.DoesNotContain(activeOnly, d => d.Id == created.Id);

        var withInactive = await manager.GetDefinitionsByEntityAsync(
            CustomFieldEntityNames.Member,
            includeInactive: true);
        Assert.Contains(withInactive, d => d.Id == created.Id && !d.IsActive);

        await manager.ActivateDefinitionAsync(created.Id);
        await manager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
        {
            EntityName = CustomFieldEntityNames.Member,
            EntityId = 10,
            Values = new List<CustomFieldValueItemDto>
            {
                new() { CustomFieldDefinitionId = created.Id, Value = "Chess" }
            }
        }, requireAllRequiredFields: false);

        await manager.DeleteDefinitionAsync(created.Id);
        Assert.Null(await manager.GetDefinitionByIdAsync(created.Id));
        Assert.Empty(await db.CustomFieldValues
            .IgnoreQueryFilters()
            .Where(v => v.CustomFieldDefinitionId == created.Id)
            .ToListAsync());
    }

    [Fact]
    public async Task Critical_field_cannot_be_deactivated_or_deleted()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var defs = await manager.GetDefinitionsByEntityAsync(CustomFieldEntityNames.Member, includeInactive: true);
        var name1 = defs.Single(d => d.Name == "name1");
        Assert.True(name1.Id > 0);

        await Assert.ThrowsAsync<ValidationException>(() => manager.DeactivateDefinitionAsync(name1.Id));
        await Assert.ThrowsAsync<ValidationException>(() => manager.DeleteDefinitionAsync(name1.Id));
    }

    [Fact]
    public async Task Built_in_non_critical_delete_tombstones()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var defs = await manager.GetDefinitionsByEntityAsync(CustomFieldEntityNames.Member, includeInactive: true);
        var gender = defs.Single(d => d.Name == "gender");

        await manager.DeleteDefinitionAsync(gender.Id);

        var row = await db.CustomFieldDefinitions
            .IgnoreQueryFilters()
            .SingleAsync(d => d.Id == gender.Id);
        Assert.True(row.IsPermanentlyDeleted);
        Assert.False(row.IsActive);

        var after = await manager.GetDefinitionsByEntityAsync(CustomFieldEntityNames.Member, includeInactive: true);
        Assert.DoesNotContain(after, d => d.Name == "gender" && d.Id > 0);
    }

    [Fact]
    public async Task Incompatible_data_type_change_blocked()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var created = await manager.CreateDefinitionAsync(CreateDto("Score", CustomFieldDataType.Number));
        await manager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
        {
            EntityName = CustomFieldEntityNames.Member,
            EntityId = 10,
            Values = new List<CustomFieldValueItemDto>
            {
                new() { CustomFieldDefinitionId = created.Id, Value = "42" }
            }
        }, requireAllRequiredFields: false);

        var check = await manager.CheckDataTypeChangeAsync(created.Id, CustomFieldDataType.Boolean);
        Assert.False(check.CanChange);
        Assert.True(check.InvalidValueCount > 0);

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.UpdateDefinitionAsync(created.Id, new CustomFieldDefinitionUpdateDto
            {
                DisplayName = "Score",
                DataType = CustomFieldDataType.Boolean
            }));
    }

    [Fact]
    public async Task Save_update_clear_and_validate_values()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var optional = await manager.CreateDefinitionAsync(CreateDto("Nickname", CustomFieldDataType.Text));
        var required = await manager.CreateDefinitionAsync(CreateDto(
            "Code",
            CustomFieldDataType.Text,
            configure: d =>
            {
                d.IsRequired = true;
                d.ValidationRegex = "^[A-Z]{3}$";
            }));
        var number = await manager.CreateDefinitionAsync(CreateDto("Points", CustomFieldDataType.Number));
        var boolean = await manager.CreateDefinitionAsync(CreateDto("Flag", CustomFieldDataType.Boolean));
        var select = await manager.CreateDefinitionAsync(CreateDto(
            "Color",
            CustomFieldDataType.SingleSelect,
            configure: d => d.Options = new List<CustomFieldOptionDto>
            {
                new() { Value = "A", DisplayText = "Alpha" },
                new() { Value = "B", DisplayText = "Beta" }
            }));

        await manager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
        {
            EntityName = CustomFieldEntityNames.Member,
            EntityId = 10,
            Values = new List<CustomFieldValueItemDto>
            {
                new() { CustomFieldDefinitionId = optional.Id, Value = "ملاحظة 🙏" },
                new() { CustomFieldDefinitionId = required.Id, Value = "ABC" },
                new() { CustomFieldDefinitionId = number.Id, Value = "7" },
                new() { CustomFieldDefinitionId = boolean.Id, Value = "1" },
                new() { CustomFieldDefinitionId = select.Id, Value = "A" }
            }
        });

        var entity = await manager.GetEntityFieldsAsync(CustomFieldEntityNames.Member, 10);
        Assert.Equal("ملاحظة 🙏", entity.Values.Single(v => v.CustomFieldDefinitionId == optional.Id).Value);
        Assert.Equal("true", entity.Values.Single(v => v.CustomFieldDefinitionId == boolean.Id).Value);

        await manager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
        {
            EntityName = CustomFieldEntityNames.Member,
            EntityId = 10,
            Values = new List<CustomFieldValueItemDto>
            {
                new() { CustomFieldDefinitionId = optional.Id, Value = "" },
                new() { CustomFieldDefinitionId = required.Id, Value = "ABC" }
            }
        }, requireAllRequiredFields: false);

        entity = await manager.GetEntityFieldsAsync(CustomFieldEntityNames.Member, 10);
        Assert.Null(entity.Values.Single(v => v.CustomFieldDefinitionId == optional.Id).Value);

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
            {
                EntityName = CustomFieldEntityNames.Member,
                EntityId = 10,
                Values = new List<CustomFieldValueItemDto>
                {
                    new() { CustomFieldDefinitionId = required.Id, Value = "abc" }
                }
            }, requireAllRequiredFields: false));

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
            {
                EntityName = CustomFieldEntityNames.Member,
                EntityId = 10,
                Values = new List<CustomFieldValueItemDto>
                {
                    new() { CustomFieldDefinitionId = number.Id, Value = "12.5" }
                }
            }, requireAllRequiredFields: false));

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
            {
                EntityName = CustomFieldEntityNames.Member,
                EntityId = 10,
                Values = new List<CustomFieldValueItemDto>
                {
                    new() { CustomFieldDefinitionId = select.Id, Value = "Z" }
                }
            }, requireAllRequiredFields: false));

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
            {
                EntityName = CustomFieldEntityNames.Member,
                EntityId = 0,
                Values = new List<CustomFieldValueItemDto>()
            }));

        await Assert.ThrowsAsync<NotFoundException>(() =>
            manager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
            {
                EntityName = CustomFieldEntityNames.Member,
                EntityId = 999999,
                Values = new List<CustomFieldValueItemDto>()
            }, requireAllRequiredFields: false));
    }

    [Fact]
    public async Task Required_field_missing_is_rejected_and_sql_string_is_stored_safely()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var required = await manager.CreateDefinitionAsync(CreateDto(
            "MustHave",
            CustomFieldDataType.Text,
            configure: d => d.IsRequired = true));
        var notes = await manager.CreateDefinitionAsync(CreateDto("SafeNotes", CustomFieldDataType.Text));

        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
            {
                EntityName = CustomFieldEntityNames.Member,
                EntityId = 10,
                Values = new List<CustomFieldValueItemDto>
                {
                    new() { CustomFieldDefinitionId = notes.Id, Value = "only notes" }
                }
            }));

        var evil = "'; DROP TABLE CustomFieldValues;--";
        await manager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
        {
            EntityName = CustomFieldEntityNames.Member,
            EntityId = 10,
            Values = new List<CustomFieldValueItemDto>
            {
                new() { CustomFieldDefinitionId = required.Id, Value = "ok" },
                new() { CustomFieldDefinitionId = notes.Id, Value = evil }
            }
        });

        var entity = await manager.GetEntityFieldsAsync(CustomFieldEntityNames.Member, 10);
        Assert.Equal(evil, entity.Values.Single(v => v.CustomFieldDefinitionId == notes.Id).Value);
        Assert.NotEmpty(await db.CustomFieldDefinitions.ToListAsync());
    }

    [Fact]
    public async Task Servant_cannot_write_readonly_but_admin_can()
    {
        var (connection, db, tenant, user, adminManager) = await CreateAsync("Admin");
        await using var _ = connection;
        await using var __ = db;

        var created = await adminManager.CreateDefinitionAsync(CreateDto(
            "Locked",
            CustomFieldDataType.Text,
            configure: d => d.IsReadOnly = true));

        user.Setup(u => u.IsInRole("Admin")).Returns(false);
        user.Setup(u => u.IsInRole("Servant")).Returns(true);

        var servantManager = CreateManager(db, tenant, user.Object);

        await Assert.ThrowsAsync<ValidationException>(() =>
            servantManager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
            {
                EntityName = CustomFieldEntityNames.Member,
                EntityId = 10,
                Values = new List<CustomFieldValueItemDto>
                {
                    new() { CustomFieldDefinitionId = created.Id, Value = "nope" }
                }
            }, requireAllRequiredFields: false));

        user.Setup(u => u.IsInRole("Admin")).Returns(true);
        user.Setup(u => u.IsInRole("Servant")).Returns(false);

        await adminManager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
        {
            EntityName = CustomFieldEntityNames.Member,
            EntityId = 10,
            Values = new List<CustomFieldValueItemDto>
            {
                new() { CustomFieldDefinitionId = created.Id, Value = "admin-ok" }
            }
        }, requireAllRequiredFields: false);
    }

    [Fact]
    public async Task Cross_tenant_member_and_definition_ids_are_isolated()
    {
        var (connection, db, tenant, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var created = await manager.CreateDefinitionAsync(CreateDto("LocalOnly", CustomFieldDataType.Text));

        await Assert.ThrowsAsync<NotFoundException>(() =>
            manager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
            {
                EntityName = CustomFieldEntityNames.Member,
                EntityId = 20,
                Values = new List<CustomFieldValueItemDto>
                {
                    new() { CustomFieldDefinitionId = created.Id, Value = "x" }
                }
            }, requireAllRequiredFields: false));

        tenant.ChurchId = 2;
        await Assert.ThrowsAsync<ValidationException>(() =>
            manager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
            {
                EntityName = CustomFieldEntityNames.Member,
                EntityId = 20,
                Values = new List<CustomFieldValueItemDto>
                {
                    new() { CustomFieldDefinitionId = created.Id, Value = "x" }
                }
            }, requireAllRequiredFields: false));
    }

    [Fact]
    public async Task Church_entity_value_save_is_broken_EntityExists_gap()
    {
        var (connection, db, _, _, manager) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        var created = await manager.CreateDefinitionAsync(CreateDto(
            "Motto",
            CustomFieldDataType.Text,
            entityName: CustomFieldEntityNames.Church));

        // Documented bug CF-BUG-001: Church is a supported entityName for definitions,
        // but EntityExistsAsync does not handle Church.
        await Assert.ThrowsAsync<NotFoundException>(() =>
            manager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
            {
                EntityName = CustomFieldEntityNames.Church,
                EntityId = 1,
                Values = new List<CustomFieldValueItemDto>
                {
                    new() { CustomFieldDefinitionId = created.Id, Value = "Grace" }
                }
            }, requireAllRequiredFields: false));
    }

    [Fact]
    public async Task Unauthenticated_cannot_save_values()
    {
        var (connection, db, tenant, user, _) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        user.SetupGet(u => u.IsAuthenticated).Returns(false);
        var manager = CreateManager(db, tenant, user.Object);

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            manager.SaveEntityValuesAsync(new SaveCustomFieldValuesDto
            {
                EntityName = CustomFieldEntityNames.Member,
                EntityId = 10,
                Values = new List<CustomFieldValueItemDto>()
            }, requireAllRequiredFields: false));
    }

    private static IMapper BuildMapper()
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddAutoMapper(m => m.AddProfile(new MappingProfile()));
        return services.BuildServiceProvider().GetRequiredService<IMapper>();
    }

    private static CustomFieldManager CreateManager(
        ProgramContext db,
        TenantContextState tenant,
        ICurrentUserContext user)
    {
        var userStore = new Mock<IUserStore<ApplicationUser>>();
        var userManager = new Mock<UserManager<ApplicationUser>>(
            userStore.Object, null!, null!, null!, null!, null!, null!, null!, null!);

        return new CustomFieldManager(
            new CustomFieldRepository(db),
            new CustomFieldValidator(),
            BuildMapper(),
            tenant,
            user,
            userManager.Object,
            NullLogger<CustomFieldManager>.Instance);
    }
}
