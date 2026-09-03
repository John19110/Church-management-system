using Church.API.Middlewares;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging.Abstractions;

namespace Church.Tests;

public sealed class GlobalExceptionMiddlewareTests
{
    [Fact]
    public async Task InvokeAsync_returns_problem_details_without_secondary_exception()
    {
        var context = new DefaultHttpContext();
        context.Response.Body = new MemoryStream();

        RequestDelegate next = _ => throw new InvalidOperationException("boom");

        var middleware = new GlobalExceptionMiddleware(
            next,
            NullLogger<GlobalExceptionMiddleware>.Instance);

        await middleware.InvokeAsync(context);

        Assert.Equal(StatusCodes.Status400BadRequest, context.Response.StatusCode);
        Assert.Equal("application/problem+json; charset=utf-8", context.Response.ContentType);

        context.Response.Body.Position = 0;
        using var reader = new StreamReader(context.Response.Body);
        var body = await reader.ReadToEndAsync();

        Assert.Contains("INVALID_OPERATION", body);
        // InvalidOperationException is also raised inside EF Core/Identity, where the message
        // describes internal state. The client gets a generic detail; the real message is logged.
        Assert.DoesNotContain("boom", body);
    }
}
