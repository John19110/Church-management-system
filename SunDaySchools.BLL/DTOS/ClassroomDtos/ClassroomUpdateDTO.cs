using System.Collections.Generic;

namespace SunDaySchools.BLL.DTOS.ClsssroomDtos
{
    public class ClassroomUpdateDTO
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? AgeOfMembers { get; set; }
        public int? MeetingId { get; set; }
        public int? LeaderServantId { get; set; }

        /// Replace assignments if provided (null => no change).
        public List<int>? ServantIds { get; set; }
        public List<int>? MemberIds { get; set; }
    }
}

