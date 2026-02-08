namespace SunDaySchools.Models
{
    public class Classroom
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? AgeOfChildren { get; set; }
        public ICollection<Child>? Children { get; set; }
        public int? NumberOfDisplineChildren { get; set; }
        public int? TotalChildrenCount => Children?.Count ?? 0;
        public ICollection<Servant>? Servants { get; set; }


    }
}
