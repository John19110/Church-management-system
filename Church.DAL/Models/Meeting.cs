using Church.Domain;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Church.DAL.Models
{
    public class Meeting 
    {
        public int Id { get; set; }

        public string PublicId { get; set; } = string.Empty;

        public string? Name { get; set; }
        public int ChurchId { get; set; }

        
        public TimeOnly Weekly_appointment { get; set; }
        public string DayOfWeek { get; set; } = string.Empty;

        /// <summary>
        /// When true, members/servants/attendance are organized under classrooms.
        /// When false, members and attendance are managed directly on the meeting.
        /// Defaults to true for backward compatibility with existing meetings.
        /// </summary>
        public bool HasClassrooms { get; set; } = true;

        /// <summary>
        /// How servants view members in this meeting.
        /// Defaults to <see cref="MemberViewMode.AssignedOnly"/> (current behavior).
        /// When <see cref="MemberViewMode.AllAndAssigned"/>, only servants listed in
        /// <see cref="AllMembersViewers"/> may open the all-members view.
        /// </summary>
        public MemberViewMode MemberViewMode { get; set; } = MemberViewMode.AssignedOnly;

        public ICollection<MeetingAllMembersViewer> AllMembersViewers { get; set; }
            = new List<MeetingAllMembersViewer>();

        public ChurchModel? Church { get; set; }
        public ICollection<Servant> Servants { get; set; } = new List<Servant>();
        public ICollection<Member> Members { get; set; } = new List<Member>();
        public ICollection<AttendanceSession> AttendanceSessions { get; set; } = new List<AttendanceSession>();
        public ICollection<AttendanceCriterion> AttendanceCriteria { get; set; } = new List<AttendanceCriterion>();

        public int? LeaderServantId { get; set; }  // Nullable if a meeting may not have a leader yet
        public Servant? LeaderServant { get; set; }



    }
}
