namespace Church.DAL.Models
{
    /// <summary>
    /// Lifecycle of a church user's registration request.
    /// Stored as an integer column on <c>AspNetUsers</c>.
    /// </summary>
    public enum RegistrationStatus
    {
        Pending = 0,
        Approved = 1,
        Rejected = 2
    }
}
