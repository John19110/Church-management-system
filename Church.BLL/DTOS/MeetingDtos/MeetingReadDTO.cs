using Church.DAL.Models;
using Church.Domain;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Church.BLL.DTOS.MeetingDtos
{
    public class MeetingReadDTO
    {

            public int Id { get; set; }
            public string PublicId { get; set; } = string.Empty;
            public string? Name { get; set; }
            public TimeOnly WeeklyAppointment { get; set; }
            public string DayOfWeek { get; set; } = string.Empty;
            public bool HasClassrooms { get; set; } = true;
            public MemberViewMode MemberViewMode { get; set; } = MemberViewMode.AssignedOnly;

            /// <summary>
            /// Servant ids allowed to open the All Members view when mode is AllAndAssigned.
            /// </summary>
            public List<int> AllMembersViewerServantIds { get; set; } = new();

            /// <summary>
            /// Whether the current caller may open the All Members view for this meeting.
            /// </summary>
            public bool CanViewAllMembers { get; set; }

            public ICollection<Servant>? Servants { get; set; }
            public ICollection<Member>? Members { get; set; }
        public int? LeaderServantId { get; set; }  // Nullable if a meeting may not have a leader yet



    }
}

