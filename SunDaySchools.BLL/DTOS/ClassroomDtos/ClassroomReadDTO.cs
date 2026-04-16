using System.Collections.Generic;

namespace SunDaySchools.BLL.DTOS
{
    public class ClassroomReadDTO
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? AgeOfMembers { get; set; }
        public ICollection<MemberReadDTO>? Members { get; set; }
        public int? NumberOfDisplineMembers { get; set; }
        public int? TotalMembersCount => Members?.Count ?? 0;
        public ICollection<ServantReadDTO>? Servants { get; set; }

        /// <summary>Number of completed attendance sessions for this classroom.</summary>
        public int PastAttendanceSessionsCount { get; set; }

        public int? LeaderServantId { get; set; }  // Nullable if a meeting may not have a leader yet




    }
}
