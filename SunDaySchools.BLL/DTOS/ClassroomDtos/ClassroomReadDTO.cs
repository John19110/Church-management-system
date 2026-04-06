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
        public string? AgeOfMembers { get; set; }
        public ICollection<Member>? Members { get; set; }
        public int? NumberOfDisplineMembers { get; set; }
        public int? TotalMembersCount => Members?.Count ?? 0;
        public ICollection<Servant>? Servants { get; set; }
        public ICollection<AttendanceSession>? AttendanceHistory { get; set; }

        public int? LeaderServantId { get; set; }  // Nullable if a meeting may not have a leader yet




    }
}
