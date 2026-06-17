namespace SunDaySchools.BLL.DTOS.AccountDtos
{
    /// <summary>
    /// Super Admin approval payload. <see cref="MeetingId"/> is required for
    /// roles that must be assigned to a meeting (Servant / Meeting Admin).
    /// </summary>
    public class ApproveUserDTO
    {
        public int? MeetingId { get; set; }
    }
}
