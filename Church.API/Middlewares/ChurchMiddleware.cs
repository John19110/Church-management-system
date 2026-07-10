public class ChurchMiddleware
{
    private readonly RequestDelegate _next;

    public ChurchMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task Invoke(HttpContext context)
    {
        var churchClaim = context.User.FindFirst("ChurchId")?.Value;
        var scopeClaim = context.User.FindFirst("Scope")?.Value;
        var classroomIdsClaim = context.User.FindFirst("ClassroomIds")?.Value;

      //  var churchIdHeader = context.Request.Headers["ChurchId"].FirstOrDefault();

              if (int.TryParse(churchClaim, out var churchId))
        {
            context.Items["ChurchId"] = churchId; 
        }

        if (!string.IsNullOrWhiteSpace(scopeClaim))
        {
            context.Items["Scope"] = scopeClaim;
        }

        if (!string.IsNullOrWhiteSpace(classroomIdsClaim))
        {
            var ids = classroomIdsClaim
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .Select(s => int.TryParse(s, out var id) ? (int?)id : null)
                .Where(id => id.HasValue)
                .Select(id => id!.Value)
                .Distinct()
                .ToList();

            context.Items["ClassroomIds"] = ids;
        }

        await _next(context);
    }
}




//    public async Task Invoke(HttpContext context)
//    {
//        // 🔹 Read from JWT claims (NOT headers)
//      

//        await _next(context);
//    }
//}