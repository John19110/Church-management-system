using Church.API.Infrastructure.Tenant;
using Church.DAL.Abstractions;
using Microsoft.AspNetCore.Http;
using System.Security.Claims;

namespace Church.Tests;

public sealed class TenantContextPopulationMiddlewareTests
{
    [Fact]
    public async Task InvokeAsync_populates_tenant_from_jwt_claims()
    {
        var tenant = new TenantContextState();
        var context = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(
                new[]
                {
                    new Claim("ChurchId", "1"),
                    new Claim("MeetingId", "2"),
                    new Claim("Scope", "Classroom"),
                    new Claim("ClassroomIds", "10,11"),
                    new Claim(ClaimTypes.Role, "Servant"),
                },
                authenticationType: "Test"))
        };

        var invoked = false;
        RequestDelegate next = _ =>
        {
            invoked = true;
            return Task.CompletedTask;
        };

        var middleware = new TenantContextPopulationMiddleware(next);
        await middleware.InvokeAsync(context, tenant);

        Assert.True(invoked);
        Assert.Equal(1, tenant.ChurchId);
        Assert.Equal(2, tenant.MeetingId);
        Assert.Equal("Classroom", tenant.Scope);
        Assert.Equal(new[] { 10, 11 }, tenant.ClassroomIds);
    }

    [Fact]
    public async Task InvokeAsync_does_not_throw_for_anonymous_user()
    {
        var tenant = new TenantContextState();
        var context = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity())
        };

        var invoked = false;
        RequestDelegate next = _ =>
        {
            invoked = true;
            return Task.CompletedTask;
        };

        var middleware = new TenantContextPopulationMiddleware(next);
        await middleware.InvokeAsync(context, tenant);

        Assert.True(invoked);
        Assert.Null(tenant.ChurchId);
        Assert.Null(tenant.MeetingId);
    }
}
