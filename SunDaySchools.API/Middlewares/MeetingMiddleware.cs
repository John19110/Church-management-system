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
        // SuperAdmin should not be globally scoped to a single meeting.
        // They can navigate across meetings within their church, so keep MeetingId unset
        // to avoid global query filters restricting results.
        if (context.User.IsInRole("SuperAdmin"))
        {
            await _next(context);
            return;
        }

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