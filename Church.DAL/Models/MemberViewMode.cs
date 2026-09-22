namespace Church.DAL.Models
{
    /// <summary>
    /// Controls how servants view members within a meeting.
    /// </summary>
    public enum MemberViewMode
    {
        /// <summary>Servants see only members they are assigned/authorized to access.</summary>
        AssignedOnly = 0,

        /// <summary>
        /// Selected servants may view all meeting members (and still have an assigned view).
        /// Which servants is stored in <see cref="Meeting.AllMembersViewers"/>.
        /// </summary>
        AllAndAssigned = 1
    }
}
