using Church.BLL.Abstractions;
using Church.BLL.DTOS.AccountDtos;
using Church.BLL.Exceptions;
using Church.BLL.Services.AccountDeletion;
using Church.BLL.Services.Email;
using Church.DAL.Abstractions;
using Church.DAL.DBcontext;
using Church.DAL.Models;
using Church.Domain;
using Microsoft.AspNetCore.Identity;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Moq;

namespace Church.Tests;

public sealed class AccountDeletionServiceTests
{
    [Fact]
    public async Task DeleteCurrentAccount_RemovesIdentityProfileImageAndRestrictiveLinks()
    {
        await using var harness = await TestHarness.CreateAsync();
        const string userId = "delete-user";
        const string imageName = "profile.png";

        var user = new ApplicationUser
        {
            Id = userId,
            UserName = "delete-user",
            NormalizedUserName = "DELETE-USER",
            PhoneNumber = "201000000001"
        };
        harness.Db.Users.Add(user);
        await harness.Db.SaveChangesAsync();

        var church = new Church.DAL.Models.Church
        {
            Name = "Test Church",
            PublicId = "TESTCHURCH"
        };
        harness.Db.Churches.Add(church);
        await harness.Db.SaveChangesAsync();

        var servant = new Servant
        {
            ApplicationUserId = userId,
            Name = "Personal Name",
            PhoneNumber = "201000000001",
            ImageFileName = imageName,
            ChurchId = church.Id
        };
        harness.Db.Servants.Add(servant);
        await harness.Db.SaveChangesAsync();

        church.PastorId = servant.Id;
        await harness.Db.SaveChangesAsync();

        harness.CurrentUser.SetupGet(x => x.IsAuthenticated).Returns(true);
        harness.CurrentUser.SetupGet(x => x.UserId).Returns(userId);

        var webRoot = Path.Combine(
            Path.GetTempPath(),
            $"church-account-deletion-{Guid.NewGuid():N}");
        var imagesDirectory = Path.Combine(webRoot, "images");
        Directory.CreateDirectory(imagesDirectory);
        var imagePath = Path.Combine(imagesDirectory, imageName);
        await File.WriteAllTextAsync(imagePath, "personal image");

        try
        {
            await harness.Service.DeleteCurrentAccountAsync(webRoot);

            harness.Db.ChangeTracker.Clear();
            Assert.False(await harness.Db.Users.AnyAsync(x => x.Id == userId));
            Assert.False(await harness.Db.Servants.IgnoreQueryFilters()
                .AnyAsync(x => x.ApplicationUserId == userId));
            Assert.Null((await harness.Db.Churches.IgnoreQueryFilters().SingleAsync()).PastorId);
            Assert.False(File.Exists(imagePath));
        }
        finally
        {
            if (Directory.Exists(webRoot))
                Directory.Delete(webRoot, recursive: true);
        }
    }

    [Fact]
    public async Task RequestDeletion_DoesNotDeleteAccount_AndTracksExpiringToken()
    {
        await using var harness = await TestHarness.CreateAsync();
        var user = new ApplicationUser
        {
            Id = "req-user",
            UserName = "req-user",
            NormalizedUserName = "REQ-USER",
            PhoneNumber = "201011122233",
            Email = "owner@example.com",
            NormalizedEmail = "OWNER@EXAMPLE.COM"
        };
        harness.Db.Users.Add(user);
        await harness.Db.SaveChangesAsync();

        var response = await harness.Service.RequestDeletionAsync(
            new CreateAccountDeletionRequestDto
            {
                Email = "owner@example.com",
                PhoneNumber = "201011122233"
            },
            "127.0.0.1");

        Assert.Contains("confirmation link", response.Message, StringComparison.OrdinalIgnoreCase);
        Assert.True(await harness.Db.Users.AnyAsync(u => u.Id == user.Id));

        var request = Assert.Single(harness.Db.AccountDeletionRequests);
        Assert.Equal(AccountDeletionRequestStatus.PendingVerification, request.Status);
        Assert.True(request.ExpiresAtUtc > DateTime.UtcNow.AddHours(23));
        Assert.NotEqual(string.Empty, request.TokenHash);
        Assert.Single(harness.Email.Sent);
        Assert.Equal("owner@example.com", harness.Email.Sent[0].To);
        Assert.Contains("/account-deletion?token=", harness.Email.Sent[0].Body, StringComparison.Ordinal);
    }

    [Fact]
    public async Task RequestDeletion_WithMismatchedStoredEmail_DoesNotCreateRequest()
    {
        await using var harness = await TestHarness.CreateAsync();
        harness.Db.Users.Add(new ApplicationUser
        {
            Id = "mismatch-user",
            UserName = "mismatch-user",
            NormalizedUserName = "MISMATCH-USER",
            PhoneNumber = "201011122244",
            Email = "stored@example.com",
            NormalizedEmail = "STORED@EXAMPLE.COM"
        });
        await harness.Db.SaveChangesAsync();

        await harness.Service.RequestDeletionAsync(
            new CreateAccountDeletionRequestDto
            {
                Email = "attacker@example.com",
                PhoneNumber = "201011122244"
            },
            null);

        Assert.Empty(harness.Db.AccountDeletionRequests);
        Assert.Empty(harness.Email.Sent);
    }

    [Fact]
    public async Task ConfirmDeletion_WithValidToken_DeletesAccount()
    {
        await using var harness = await TestHarness.CreateAsync();
        var user = new ApplicationUser
        {
            Id = "confirm-user",
            UserName = "confirm-user",
            NormalizedUserName = "CONFIRM-USER",
            PhoneNumber = "201011122255"
        };
        harness.Db.Users.Add(user);
        await harness.Db.SaveChangesAsync();

        await harness.Service.RequestDeletionAsync(
            new CreateAccountDeletionRequestDto
            {
                Email = "confirm@example.com",
                PhoneNumber = "201011122255"
            },
            null);

        var token = ExtractToken(harness.Email.Sent[0].Body);
        var webRoot = Path.Combine(Path.GetTempPath(), $"church-del-confirm-{Guid.NewGuid():N}");
        Directory.CreateDirectory(webRoot);

        try
        {
            await harness.Service.ConfirmDeletionAsync(
                new ConfirmAccountDeletionRequestDto { Token = token },
                webRoot);

            harness.Db.ChangeTracker.Clear();
            Assert.False(await harness.Db.Users.AnyAsync(u => u.Id == user.Id));
        }
        finally
        {
            if (Directory.Exists(webRoot))
                Directory.Delete(webRoot, recursive: true);
        }
    }

    [Fact]
    public async Task ConfirmDeletion_WithExpiredToken_DoesNotDeleteAccount()
    {
        await using var harness = await TestHarness.CreateAsync();
        var user = new ApplicationUser
        {
            Id = "expired-user",
            UserName = "expired-user",
            NormalizedUserName = "EXPIRED-USER",
            PhoneNumber = "201011122266"
        };
        harness.Db.Users.Add(user);
        await harness.Db.SaveChangesAsync();

        await harness.Service.RequestDeletionAsync(
            new CreateAccountDeletionRequestDto
            {
                Email = "expired@example.com",
                PhoneNumber = "201011122266"
            },
            null);

        var request = await harness.Db.AccountDeletionRequests.SingleAsync();
        request.ExpiresAtUtc = DateTime.UtcNow.AddMinutes(-1);
        await harness.Db.SaveChangesAsync();

        var token = ExtractToken(harness.Email.Sent[0].Body);
        var webRoot = Path.Combine(Path.GetTempPath(), $"church-del-expired-{Guid.NewGuid():N}");
        Directory.CreateDirectory(webRoot);

        try
        {
            await Assert.ThrowsAsync<ValidationException>(() =>
                harness.Service.ConfirmDeletionAsync(
                    new ConfirmAccountDeletionRequestDto { Token = token },
                    webRoot));

            harness.Db.ChangeTracker.Clear();
            Assert.True(await harness.Db.Users.AnyAsync(u => u.Id == user.Id));
            Assert.Equal(
                AccountDeletionRequestStatus.Expired,
                (await harness.Db.AccountDeletionRequests.SingleAsync()).Status);
        }
        finally
        {
            if (Directory.Exists(webRoot))
                Directory.Delete(webRoot, recursive: true);
        }
    }

    private static string ExtractToken(string emailBody)
    {
        const string marker = "/account-deletion?token=";
        var start = emailBody.IndexOf(marker, StringComparison.Ordinal);
        Assert.True(start >= 0);
        start += marker.Length;
        var end = start;
        while (end < emailBody.Length
               && !char.IsWhiteSpace(emailBody[end])
               && emailBody[end] != '"'
               && emailBody[end] != '<')
        {
            end++;
        }

        return Uri.UnescapeDataString(emailBody[start..end]);
    }

    private sealed class RecordingEmailSender : IEmailSender
    {
        public List<(string To, string Subject, string Body)> Sent { get; } = new();

        public Task SendAsync(
            string toAddress,
            string subject,
            string plainTextBody,
            string? htmlBody = null,
            CancellationToken cancellationToken = default)
        {
            Sent.Add((toAddress, subject, plainTextBody));
            return Task.CompletedTask;
        }
    }

    private sealed class TestHarness : IAsyncDisposable
    {
        private readonly SqliteConnection _connection;

        private TestHarness(
            SqliteConnection connection,
            ProgramContext db,
            AccountDeletionService service,
            Mock<ICurrentUserContext> currentUser,
            RecordingEmailSender email)
        {
            _connection = connection;
            Db = db;
            Service = service;
            CurrentUser = currentUser;
            Email = email;
        }

        public ProgramContext Db { get; }
        public AccountDeletionService Service { get; }
        public Mock<ICurrentUserContext> CurrentUser { get; }
        public RecordingEmailSender Email { get; }

        public static async Task<TestHarness> CreateAsync()
        {
            var connection = new SqliteConnection("Data Source=:memory:");
            await connection.OpenAsync();

            var tenant = new Mock<ITenantContext>();
            tenant.SetupGet(x => x.ClassroomIds).Returns(Array.Empty<int>());
            var options = new DbContextOptionsBuilder<ProgramContext>()
                .UseSqlite(connection)
                .Options;
            var db = new ProgramContext(options, tenant.Object);
            await db.Database.EnsureCreatedAsync();

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
            var unitOfWork = new UnitOfWork(db, NullLogger<UnitOfWork>.Instance);
            var email = new RecordingEmailSender();
            var deletionOptions = Options.Create(new AccountDeletionOptions
            {
                PublicBaseUrl = "https://example.test",
                TokenLifetimeHours = 24
            });

            var service = new AccountDeletionService(
                db,
                userManager.Object,
                currentUser.Object,
                unitOfWork,
                email,
                deletionOptions,
                NullLogger<AccountDeletionService>.Instance);

            return new TestHarness(connection, db, service, currentUser, email);
        }

        public async ValueTask DisposeAsync()
        {
            await Db.DisposeAsync();
            await _connection.DisposeAsync();
        }
    }
}
