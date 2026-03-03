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

        public int? TakenByServantId { get; set; }

        public string? Notes { get; set; }
        public List<AttendanceRecordReadDTO> Records { get; set; } = new();
    }
}
