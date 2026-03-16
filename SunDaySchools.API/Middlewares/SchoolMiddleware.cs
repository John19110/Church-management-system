public class SchoolMiddleware
{
    private readonly RequestDelegate _next;

    public SchoolMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task Invoke(HttpContext context)
    {
        var host = context.Request.Host.Host;
        var subdomain = host.Split('.')[0];

        context.Items["SchoolId"] = subdomain;

        await _next(context);
    }
}