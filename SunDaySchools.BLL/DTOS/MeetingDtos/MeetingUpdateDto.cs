using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.DTOS.MeetingDtos
{
    public class MeetingUpdateDto
    {
        public string? Name { get; set; }
        public TimeOnly? WeeklyAppointment { get; set; }
        public string? DayOfWeek { get; set; }

        // Nullable if a meeting may not have a leader yet
        public int? LeaderServantId { get; set; }

    }
}
