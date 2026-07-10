using Church.Domain;

namespace Church.DAL.Models
{
    public class Church
    {
        public int Id { get; set; }

        public string PublicId { get; set; } = string.Empty;

        public string Name { get; set; }

        public ICollection<Member> Members { get; set; } = new List<Member>();
        public ICollection<Servant> Servants { get; set; } = new List<Servant>();
        public ICollection<Meeting> Meetings { get; set; } = new List<Meeting>();

        public int? PastorId { get; set; }
        public Servant? Pastor { get; set; }
    }
}
