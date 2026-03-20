public class ChurchMiddleware
{
    private readonly RequestDelegate _next;

    public ChurchMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task Invoke(HttpContext context)
    {
        var host = context.Request.Host.Host;
        var subdomain = host.Split('.')[0];

        context.Items["ChurchId"] = subdomain;

        await _next(context);
    }
}