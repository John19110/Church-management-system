public class MeetingMiddleware
{
    private readonly RequestDelegate _next;

    public MeetingMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task Invoke(HttpContext context)
    {
      //  var meetingIdHeader = context.Request.Headers["MeetingId"].FirstOrDefault();
        var meetingClaim = context.User.FindFirst("MeetingId")?.Value;



        if (int.TryParse(meetingClaim, out var meetingId))
        {
            context.Items["MeetingId"] = meetingId;
        }
        //if (int.TryParse(meetingIdHeader, out var meetingId))
        //{
        //    context.Items["MeetingId"] = meetingId; // ✅ int
        //}

        await _next(context);
    }
}