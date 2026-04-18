using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.DTOS.Meeting
{
    public class MeetingAddDTO
    {
        public string? Name { get; set; }
        public TimeOnly WeeklyAppointment { get; set; }
        public string DayOfWeek { get; set; } = string.Empty;
        public int? LeaderServantId { get; set; }
    }
}
