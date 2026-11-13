using Church.BLL.Abstractions;
using Church.BLL.DTOS.OptionalModules;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Implementations;
using Church.BLL.OptionalModules;
using Church.DAL.Abstractions;
using Church.DAL.DBcontext;
using Church.DAL.Models;
using Church.DAL.Models.OptionalModules;
using Church.DAL.Repository.Implementations;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Moq;

namespace Church.Tests;

public sealed class StockItemManagerTests
{
    private static async Task<(
        SqliteConnection Connection,
        ProgramContext Db,
        TenantContextState Tenant,
        Mock<ICurrentUserContext> User,
        OptionalModuleManager Modules,
        StockItemManager Stock)> CreateAsync()
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

        db.Churches.Add(new Church.DAL.Models.Church { Id = 1, Name = "A", PublicId = "church-a-00001" });
        db.Churches.Add(new Church.DAL.Models.Church { Id = 2, Name = "B", PublicId = "church-b-00002" });
        await db.SaveChangesAsync();

        var user = new Mock<ICurrentUserContext>();
        user.SetupGet(u => u.IsAuthenticated).Returns(true);
        user.SetupGet(u => u.UserId).Returns("user-1");
        user.Setup(u => u.IsInRole("SuperAdmin")).Returns(true);
        user.Setup(u => u.IsInRole("Admin")).Returns(false);
        user.Setup(u => u.IsInRole("Servant")).Returns(false);

        var modules = new OptionalModuleManager(
            new OptionalModuleRepository(db),
            tenant,
            user.Object);
        var stock = new StockItemManager(
            new StockItemRepository(db),
            modules,
            tenant,
            user.Object);

        return (connection, db, tenant, user, modules, stock);
    }

    [Fact]
    public async Task Stock_ops_blocked_when_module_disabled()
    {
        var (connection, db, _, _, _, stock) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            stock.GetAllAsync());
    }

    [Fact]
    public async Task Enable_stock_then_create_and_atomic_quantity()
    {
        var (connection, db, _, _, modules, stock) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        await modules.SetEnabledAsync(PredefinedModules.Stock, true);

        var created = await stock.CreateAsync(new StockItemCreateDto
        {
            Name = "Chairs",
            NameAr = "كراسي",
            Amount = 25
        });

        Assert.Equal(25, created.Amount);

        var increased = await stock.IncreaseAmountAsync(created.Id);
        Assert.Equal(26, increased.Amount);

        var decreased = await stock.DecreaseAmountAsync(created.Id);
        Assert.Equal(25, decreased.Amount);

        // Drive amount to zero then reject further decrease.
        for (var i = 0; i < 25; i++)
            await stock.DecreaseAmountAsync(created.Id);

        await Assert.ThrowsAsync<ValidationException>(() =>
            stock.DecreaseAmountAsync(created.Id));

        var zero = await stock.GetByIdAsync(created.Id);
        Assert.Equal(0, zero!.Amount);
    }

    [Fact]
    public async Task Concurrent_increments_do_not_lose_updates()
    {
        var (connection, db, _, _, modules, stock) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        await modules.SetEnabledAsync(PredefinedModules.Stock, true);
        var created = await stock.CreateAsync(new StockItemCreateDto
        {
            Name = "Bibles",
            Amount = 0
        });

        var tasks = Enumerable.Range(0, 20)
            .Select(_ => stock.IncreaseAmountAsync(created.Id))
            .ToArray();
        await Task.WhenAll(tasks);

        var final = await stock.GetByIdAsync(created.Id);
        Assert.Equal(20, final!.Amount);
    }

    [Fact]
    public async Task ChurchB_cannot_see_ChurchA_stock()
    {
        var (connection, db, tenant, _, modules, stock) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        await modules.SetEnabledAsync(PredefinedModules.Stock, true);
        var created = await stock.CreateAsync(new StockItemCreateDto
        {
            Name = "Tables",
            Amount = 3
        });

        tenant.ChurchId = 2;
        tenant.MeetingId = null;
        tenant.Scope = TenantScopes.Church;

        await modules.SetEnabledAsync(PredefinedModules.Stock, true);
        Assert.Null(await stock.GetByIdAsync(created.Id));
        Assert.Empty(await stock.GetAllAsync());
    }

    [Fact]
    public async Task Disable_preserves_data_and_blocks_access()
    {
        var (connection, db, _, _, modules, stock) = await CreateAsync();
        await using var _ = connection;
        await using var __ = db;

        await modules.SetEnabledAsync(PredefinedModules.Stock, true);
        var created = await stock.CreateAsync(new StockItemCreateDto
        {
            Name = "Cups",
            Amount = 10
        });

        await modules.SetEnabledAsync(PredefinedModules.Stock, false);
        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            stock.GetByIdAsync(created.Id));

        await modules.SetEnabledAsync(PredefinedModules.Stock, true);
        var restored = await stock.GetByIdAsync(created.Id);
        Assert.NotNull(restored);
        Assert.Equal(10, restored!.Amount);
        Assert.Equal("Cups", restored.Name);
    }
}
