using SunDaySchools.DAL.Models;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.DTOS.ClsssroomDtos
{
    public class ClassroomAddDTO
    {
        public string? Name { get; set; }
        public string? AgeOfChildren { get; set; }
        public List<int>? ServantIds { get; set; }
        public List<int>? MemberIds { get; set; }
        public int? MeetingId { get; set; }



    }
}
