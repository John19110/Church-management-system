using SunDaySchools.DAL.Models;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.DTOS
{
    public class ClassroomReadDTO
    {
        public string? Name { get; set; }
        public string? AgeOfChildren { get; set; }
        public ICollection<Child>? Children { get; set; }
        public int? NumberOfDisplineChildren { get; set; }
        public int? TotalChildrenCount => Children?.Count ?? 0;
        public ICollection<Servant>? Servants { get; set; }
        public ICollection<AttendanceSession>? AttendanceHistory { get; set; }



    }
}
