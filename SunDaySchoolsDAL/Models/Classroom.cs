using SunDaySchools.DAL.Models;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;

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

        /// <summary>Many-to-many assignment rows (source of truth for assigned servants).</summary>
        public ICollection<ClassroomServant> ClassroomServants { get; set; } = new List<ClassroomServant>();

        /// <summary>Assigned servants (via <see cref="ClassroomServants"/>).</summary>
        [NotMapped]
        public IEnumerable<Servant> Servants =>
            ClassroomServants.Select(cs => cs.Servant);

        public ICollection<AttendanceSession>? AttendanceHistory { get; set; }

        public int? LeaderServantId { get; set; }
        public Servant? LeaderServant { get; set; }
    }
}
