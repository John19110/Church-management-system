using Church.DAL.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Church.BLL.DTOS.MeetingDtos
{
    public class MeetingUpdateDto
    {
        public string? Name { get; set; }
        public TimeOnly? WeeklyAppointment { get; set; }
        public string? DayOfWeek { get; set; }

        // Nullable if a meeting may not have a leader yet
        public int? LeaderServantId { get; set; }

        /// <summary>
        /// When set, updates how servants view members in this meeting.
        /// </summary>
        public MemberViewMode? MemberViewMode { get; set; }

        /// <summary>
        /// When provided (including empty), replaces the set of servants allowed to
        /// view all members. Ignored unless mode is AllAndAssigned (or being set to it).
        /// Servants must belong to this meeting.
        /// </summary>
        public List<int>? AllMembersViewerServantIds { get; set; }
    }
}
