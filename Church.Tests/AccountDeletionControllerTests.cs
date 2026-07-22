using Church.API.Controllers;
using Church.BLL.Manager.Interfaces;
using Church.BLL.Services.AccountDeletion;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Moq;

namespace Church.Tests;

public sealed class AccountDeletionControllerTests
{
    [Fact]
    public async Task DeleteCurrentAccount_DeletesCurrentUser_AndReturnsNoContent()
    {
        var accountManager = new Mock<IAccountManager>();
        var deletionService = new Mock<IAccountDeletionService>();
        var environment = new Mock<IWebHostEnvironment>();
        environment.SetupGet(x => x.WebRootPath).Returns("C:\\app\\wwwroot");

        var controller = new AccountController(
            accountManager.Object,
            deletionService.Object,
            environment.Object);

        var result = await controller.DeleteCurrentAccount(CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
        deletionService.Verify(
            x => x.DeleteCurrentAccountAsync(
                "C:\\app\\wwwroot",
                CancellationToken.None),
            Times.Once);
    }

    [Fact]
    public void DeleteCurrentAccount_RequiresAuthorization()
    {
        var method = typeof(AccountController)
            .GetMethod(nameof(AccountController.DeleteCurrentAccount));

        Assert.NotNull(method);
        Assert.Contains(
            method!.GetCustomAttributes(inherit: true),
            attribute => attribute is Microsoft.AspNetCore.Authorization.AuthorizeAttribute);
    }
}
