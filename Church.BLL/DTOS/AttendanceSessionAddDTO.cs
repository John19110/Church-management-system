using Church.DAL.Models;
using Church.Domain;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Church.BLL.DTOS
{
    public class AttendanceSessionAddDTO
    {
        /// <summary>
        /// Required for meeting-level attendance (HasClassrooms=false).
        /// Optional when ClassroomId is provided (derived from the classroom).
        /// </summary>
        public int? MeetingId { get; set; }

        /// <summary>
        /// Required when the meeting uses classrooms; omit/null for meeting-level attendance.
        /// </summary>
        public int? ClassroomId { get; set; }

        public int? TakenByServantId { get; set; }
        public string? Notes { get; set; }

        public List<AttendanceRecordAddDTO> Records { get; set; } = new();
    }
}
