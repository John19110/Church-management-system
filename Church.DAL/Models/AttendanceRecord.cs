using Church.Domain;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Church.DAL.Models
{
    public class AttendanceRecord : ChurchEntity
    {


        public int Id { get; set; }
        public int AttendanceSessionId { get; set; }
        public AttendanceSession? AttendanceSession { get; set; }

        public int MemberId { get; set; }
        public Member? Member { get; set; }

        public bool MadeHomeWork { get; set; } = false;
        public bool HasTools { get; set; } = false;


        public AttendanceStatus Status { get; set; } = AttendanceStatus.Present;

        public string? Note { get; set; }

        public DateTime UpdatedAt{ get; set; } = DateTime.Now;
    }
}
