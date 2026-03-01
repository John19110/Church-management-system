using SunDaySchools.DAL.Models;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.DTOS
{
    public class AttendanceSessionAddDTO
    {
        public int ClassroomId { get; set; }

        // The day the weekly meeting happened
        public DateOnly SessionDate { get; set; }

        // Who took attendance
        public int? TakenByServantId { get; set; }

        public string? Notes { get; set; }


        // All child records for this session
        public List<AttendanceRecordAddDTO> Records { get; set; } = new();

    }
}
