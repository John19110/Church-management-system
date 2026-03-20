using SunDaySchools.DAL.Models;
using SunDaySchools.Models;

public class Church
{
    public int Id { get; set; }
    public string Name { get; set; }

    public ICollection<Child>  Children  { get; set; } = new List<Child>();
    public ICollection<Servant>  Servants  { get; set; } = new List<Servant>();
    public ICollection<Meeting> Meetings { get; set; } = new List<Meeting>();




}