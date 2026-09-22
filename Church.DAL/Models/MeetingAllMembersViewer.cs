using Church.Domain;

namespace Church.DAL.Models
{
    /// <summary>
    /// Grants a servant permission to view all members of a specific meeting
    /// when that meeting's <see cref="MemberViewMode"/> is <see cref="MemberViewMode.AllAndAssigned"/>.
    /// </summary>
    public class MeetingAllMembersViewer : ChurchEntity
    {
        public int ServantId { get; set; }
        public Servant Servant { get; set; } = default!;
    }
}
