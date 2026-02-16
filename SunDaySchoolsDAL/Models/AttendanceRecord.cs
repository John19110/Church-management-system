using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Models
{
    public class AttendanceRecord
    {


        public int Id { get; set; }
        public int AttendanceSessionId { get; set; }
        public AttendanceSession? AttendanceSession { get; set; }

        public int ChildId { get; set; }
        public Child? Child { get; set; }

        public bool MadeHomeWork { get; set; }

        public bool HasTools { get; set; }

        public AttendanceStatus Status { get; set; } = AttendanceStatus.Present;

        public string? Note { get; set; }

        public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;
    }
}
