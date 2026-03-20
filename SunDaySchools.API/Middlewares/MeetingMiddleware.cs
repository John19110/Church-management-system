public class MeetingMiddleware
{
    private readonly RequestDelegate _next;

    public MeetingMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task Invoke(HttpContext context)
    {
        var meetingId = context.Request.Headers["MeetingId"];

        if (!string.IsNullOrEmpty(meetingId))
        {
            context.Items["MeetingId"] = int.Parse(meetingId);
        }

        await _next(context);
    }
}