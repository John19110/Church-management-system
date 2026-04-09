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

      //  var churchIdHeader = context.Request.Headers["ChurchId"].FirstOrDefault();

              if (int.TryParse(churchClaim, out var churchId))
        {
            context.Items["ChurchId"] = churchId; 
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