using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.DTOS
{
    public class AttendanceSessionReadDTO
    {

        public DateOnly SessionDate { get; set; }

        // Who took attendance
        public int? TakenByServantId { get; set; }

        public string? Notes { get; set; }


        // All child records for this session
        public List<AttendanceRecordAddDTO> Records { get; set; } = new();
    }
}
