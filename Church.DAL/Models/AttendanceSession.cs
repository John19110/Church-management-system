using Church.Domain;
using System;
using System.Collections.Generic;

namespace Church.DAL.Models
{
    public class AttendanceSession
    {
        public int Id { get; set; }

        /// <summary>
        /// Always set. For classroom-scoped sessions this is the classroom's meeting.
        /// For meeting-level sessions (HasClassrooms=false) this is the only scope.
        /// </summary>
        public int MeetingId { get; set; }
        public Meeting? Meeting { get; set; }

        /// <summary>
        /// Required when the meeting uses classrooms; null for meeting-level attendance.
        /// </summary>
        public int? ClassroomId { get; set; }
        public Classroom? Classroom { get; set; }

        public int? TakenByServantId { get; set; }
        public Servant? TakenByServant { get; set; }

        public string? Notes { get; set; }

        public DateOnly CreatedAt { get; set; } = DateOnly.FromDateTime(DateTime.Today);

        public List<AttendanceRecord> Records { get; set; } = new();
    }
}
