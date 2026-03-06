using SunDaySchools.DAL.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.DTOS
{
    public class AttendanceSessionUpdateDTO
    {
        public int Id { get; set; }

        public int ClassroomId { get; set; }

        // The day the weekly meeting happened
        // Who took attendance
        public int? TakenByServantId { get; set; }

        public string? Notes { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;

        // All child records for this session
        public List<AttendanceRecordUpdateDTO> Records { get; set; } = new();


    }
}
