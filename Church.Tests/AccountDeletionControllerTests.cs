using Church.API.Controllers;
using Church.BLL.DTOS.AccountDtos;
using Church.BLL.Manager.Interfaces;
using Church.BLL.Services.AccountDeletion;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
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

    [Fact]
    public async Task RequestAccountDeletion_IsAnonymous_AndReturnsMessage()
    {
        var deletionService = new Mock<IAccountDeletionService>();
        deletionService
            .Setup(x => x.RequestDeletionAsync(
                It.IsAny<CreateAccountDeletionRequestDto>(),
                It.IsAny<string?>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AccountDeletionRequestResponseDto
            {
                Message = "ok"
            });

        var controller = CreateController(deletionService);
        controller.ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext()
        };

        var method = typeof(AccountController)
            .GetMethod(nameof(AccountController.RequestAccountDeletion));
        Assert.Contains(
            method!.GetCustomAttributes(inherit: true),
            attribute => attribute is Microsoft.AspNetCore.Authorization.AllowAnonymousAttribute);

        var result = await controller.RequestAccountDeletion(
            new CreateAccountDeletionRequestDto
            {
                Email = "a@b.com",
                PhoneNumber = "201011122233"
            },
            CancellationToken.None);

        var ok = Assert.IsType<OkObjectResult>(result.Result);
        var body = Assert.IsType<AccountDeletionRequestResponseDto>(ok.Value);
        Assert.Equal("ok", body.Message);
    }

    [Fact]
    public async Task ConfirmAccountDeletion_IsAnonymous_AndReturnsNoContent()
    {
        var deletionService = new Mock<IAccountDeletionService>();
        var controller = CreateController(deletionService);

        var method = typeof(AccountController)
            .GetMethod(nameof(AccountController.ConfirmAccountDeletion));
        Assert.Contains(
            method!.GetCustomAttributes(inherit: true),
            attribute => attribute is Microsoft.AspNetCore.Authorization.AllowAnonymousAttribute);

        var result = await controller.ConfirmAccountDeletion(
            new ConfirmAccountDeletionRequestDto { Token = "token" },
            CancellationToken.None);

        Assert.IsType<NoContentResult>(result);
        deletionService.Verify(
            x => x.ConfirmDeletionAsync(
                It.Is<ConfirmAccountDeletionRequestDto>(d => d.Token == "token"),
                "C:\\app\\wwwroot",
                CancellationToken.None),
            Times.Once);
    }

    private static AccountController CreateController(Mock<IAccountDeletionService> deletionService)
    {
        var environment = new Mock<IWebHostEnvironment>();
        environment.SetupGet(x => x.WebRootPath).Returns("C:\\app\\wwwroot");
        return new AccountController(
            new Mock<IAccountManager>().Object,
            deletionService.Object,
            environment.Object);
    }
}
