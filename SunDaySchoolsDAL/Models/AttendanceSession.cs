using SunDaySchools.Models;
using System;
using System.Collections.Generic;

namespace SunDaySchools.DAL.Models
{
    public class AttendanceSession
    {
        public int Id { get; set; }

        // One classroom per session
        public int ClassroomId { get; set; }
        public Classroom? Classroom { get; set; }

        // The day the weekly meeting happened
        public DateOnly SessionDate { get; set; }

        // Who took attendance
        public int? TakenByServantId { get; set; }
        public Servant? TakenByServant { get; set; }

        public string? Notes { get; set; }

        public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

        // All child records for this session
        public List<AttendanceRecord> Records { get; set; } = new();
    }
}
