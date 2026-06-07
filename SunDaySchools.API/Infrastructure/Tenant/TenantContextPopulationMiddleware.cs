using SunDaySchools.DAL.Abstractions;

namespace SunDaySchools.API.Infrastructure.Tenant
{
    /// <summary>
    /// Populates scoped <see cref="TenantContextState"/> from JWT claims for BLL and DAL.
    /// Replaces direct HttpContext reads in ProgramContext and business services.
    /// </summary>
    public sealed class TenantContextPopulationMiddleware
    {
        private readonly RequestDelegate _next;

        public TenantContextPopulationMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task InvokeAsync(HttpContext context, TenantContextState tenant)
        {
            var user = context.User;

            if (int.TryParse(user.FindFirst("ChurchId")?.Value, out var churchId))
            {
                tenant.ChurchId = churchId;
                context.Items["ChurchId"] = churchId;
            }

            var scopeClaim = user.FindFirst("Scope")?.Value;
            if (!string.IsNullOrWhiteSpace(scopeClaim))
            {
                tenant.Scope = scopeClaim;
                context.Items["Scope"] = scopeClaim;
            }

            var classroomIdsClaim = user.FindFirst("ClassroomIds")?.Value;
            if (!string.IsNullOrWhiteSpace(classroomIdsClaim))
            {
                var ids = classroomIdsClaim
                    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                    .Select(s => int.TryParse(s, out var id) ? (int?)id : null)
                    .Where(id => id.HasValue)
                    .Select(id => id!.Value)
                    .Distinct()
                    .ToList();

                tenant.ClassroomIds = ids;
                context.Items["ClassroomIds"] = ids;
            }

            if (!user.IsInRole("SuperAdmin")
                && int.TryParse(user.FindFirst("MeetingId")?.Value, out var meetingId))
            {
                tenant.MeetingId = meetingId;
                context.Items["MeetingId"] = meetingId;
            }

            await _next(context);
        }
    }
}
