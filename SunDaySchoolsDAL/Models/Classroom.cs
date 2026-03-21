using SunDaySchools.DAL.Models;

namespace SunDaySchools.Models
{
    public class Classroom : ChurchEntity
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? AgeOfMembers { get; set; }
        public ICollection<Member>? Members { get; set; }
        public int? NumberOfDisplineMembers { get; set; }
        public int? TotalMembersCount => Members?.Count ?? 0;
        public ICollection<Servant>? Servants { get; set; }
        public ICollection<AttendanceSession>? AttendanceHistory { get; set; }



    }
}
