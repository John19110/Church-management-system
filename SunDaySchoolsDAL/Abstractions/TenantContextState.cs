namespace SunDaySchools.DAL.Abstractions
{
    /// <summary>
    /// Mutable scoped tenant state. API middleware sets values per request.
    /// </summary>
    public sealed class TenantContextState : ITenantContext
    {
        public int? ChurchId { get; set; }
        public int? MeetingId { get; set; }
        public string? Scope { get; set; }
        public IReadOnlyList<int> ClassroomIds { get; set; } = Array.Empty<int>();
    }
}
