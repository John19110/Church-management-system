using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Church.BLL.DTOS.Meeting
{
    public class MeetingAddDTO
    {
        public string? Name { get; set; }
        public TimeOnly WeeklyAppointment { get; set; }
        public string DayOfWeek { get; set; } = string.Empty;
        public int? LeaderServantId { get; set; }

        /// <summary>
        /// Whether this meeting is divided into classrooms.
        /// Defaults to true when omitted (backward compatible).
        /// </summary>
        public bool HasClassrooms { get; set; } = true;
    }
}
