using Church.DAL.Abstractions;
using Church.DAL.DBcontext;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace Church.Tests;

public sealed class ModelSnapshotSyncTests
{
    [Fact]
    public void AddCustomFeatures_migration_is_discovered()
    {
        using var db = CreateDesignTimeContext();
        var migrations = db.Database.GetMigrations().ToList();

        Assert.Contains("20260923150000_AddCustomFeatures", migrations);
    }

    [Fact]
    public void Compiled_model_is_ahead_of_snapshot_so_runtime_must_ignore_pending_model_changes()
    {
        using var db = CreateDesignTimeContext();

        // ProgramContextModelSnapshot still stops at MeetingAllMembersViewer.
        // Custom Features exist on the compiled model and in AddCustomFeatures.Up().
        // EF Core 10 throws on that mismatch inside MigrateAsync unless the warning is ignored.
        Assert.True(db.Database.HasPendingModelChanges());
    }

    private static ProgramContext CreateDesignTimeContext()
    {
        var options = new DbContextOptionsBuilder<ProgramContext>()
            .UseSqlServer(
                "Server=unused;Database=unused;TrustServerCertificate=True",
                sql => sql.MigrationsAssembly("Church.DAL"))
            .ConfigureWarnings(w => w.Ignore(RelationalEventId.PendingModelChangesWarning))
            .Options;

        return new ProgramContext(options, new TenantContextState());
    }
}
