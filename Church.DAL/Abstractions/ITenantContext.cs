namespace Church.DAL.Abstractions
{
    /// <summary>
    /// Request-scoped tenant isolation (church, meeting, classroom scope).
    /// Populated by API middleware; consumed by DAL query filters and BLL.
    /// </summary>
    public interface ITenantContext
    {
        int? ChurchId { get; }
        int? MeetingId { get; }
        string? Scope { get; }
        IReadOnlyList<int> ClassroomIds { get; }
    }
}
