using SunDaySchools.DAL.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.DTOS
{
    public class AttendanceRecordReadDTO
    {

        public int ChildId { get; set; }
        public string? MemberName { get; set; }

        public bool MadeHomeWork { get; set; } = false;
        public bool HasTools { get; set; } = false;

        public AttendanceStatus Status { get; set; } = AttendanceStatus.Present;
        public string? Note { get; set; }
    }
}
