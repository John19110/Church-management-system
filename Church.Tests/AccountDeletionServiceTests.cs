using Church.BLL.Abstractions;
using Church.BLL.Services.AccountDeletion;
using Church.DAL.Abstractions;
using Church.DAL.DBcontext;
using Church.DAL.Models;
using Church.Domain;
using Microsoft.AspNetCore.Identity;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Church.Tests;

public sealed class AccountDeletionServiceTests
{
    [Fact]
    public async Task DeleteCurrentAccount_RemovesIdentityProfileImageAndRestrictiveLinks()
    {
        await using var connection = new SqliteConnection("Data Source=:memory:");
        await connection.OpenAsync();

        var tenant = new Mock<ITenantContext>();
        tenant.SetupGet(x => x.ClassroomIds).Returns(Array.Empty<int>());
        var options = new DbContextOptionsBuilder<ProgramContext>()
            .UseSqlite(connection)
            .Options;
        await using var db = new ProgramContext(options, tenant.Object);
        await db.Database.EnsureCreatedAsync();

        const string userId = "delete-user";
        const string imageName = "profile.png";
        var user = new ApplicationUser
        {
            Id = userId,
            UserName = "delete-user",
            NormalizedUserName = "DELETE-USER"
        };
        db.Users.Add(user);
        await db.SaveChangesAsync();

        var church = new Church.DAL.Models.Church
        {
            Name = "Test Church",
            PublicId = "TESTCHURCH"
        };
        db.Churches.Add(church);
        await db.SaveChangesAsync();

        var servant = new Servant
        {
            ApplicationUserId = userId,
            Name = "Personal Name",
            PhoneNumber = "01000000000",
            ImageFileName = imageName,
            ChurchId = church.Id
        };
        db.Servants.Add(servant);
        await db.SaveChangesAsync();

        church.PastorId = servant.Id;
        await db.SaveChangesAsync();

        var userStore = new Mock<IUserStore<ApplicationUser>>();
        var userManager = new Mock<UserManager<ApplicationUser>>(
            userStore.Object,
            null!,
            null!,
            null!,
            null!,
            null!,
            null!,
            null!,
            null!);
        userManager.SetupGet(x => x.Users).Returns(db.Users);
        userManager
            .Setup(x => x.DeleteAsync(It.IsAny<ApplicationUser>()))
            .Returns<ApplicationUser>(async account =>
            {
                db.Users.Remove(account);
                await db.SaveChangesAsync();
                return IdentityResult.Success;
            });

        var currentUser = new Mock<ICurrentUserContext>();
        currentUser.SetupGet(x => x.IsAuthenticated).Returns(true);
        currentUser.SetupGet(x => x.UserId).Returns(userId);
        var unitOfWork = new UnitOfWork(
            db,
            NullLogger<UnitOfWork>.Instance);
        var service = new AccountDeletionService(
            db,
            userManager.Object,
            currentUser.Object,
            unitOfWork,
            NullLogger<AccountDeletionService>.Instance);

        var webRoot = Path.Combine(
            Path.GetTempPath(),
            $"church-account-deletion-{Guid.NewGuid():N}");
        var imagesDirectory = Path.Combine(webRoot, "images");
        Directory.CreateDirectory(imagesDirectory);
        var imagePath = Path.Combine(imagesDirectory, imageName);
        await File.WriteAllTextAsync(imagePath, "personal image");

        try
        {
            await service.DeleteCurrentAccountAsync(webRoot);

            db.ChangeTracker.Clear();
            Assert.False(await db.Users.AnyAsync(x => x.Id == userId));
            Assert.False(await db.Servants.IgnoreQueryFilters()
                .AnyAsync(x => x.ApplicationUserId == userId));
            Assert.Null((await db.Churches.SingleAsync()).PastorId);
            Assert.False(File.Exists(imagePath));
        }
        finally
        {
            if (Directory.Exists(webRoot))
                Directory.Delete(webRoot, recursive: true);
        }
    }
}
