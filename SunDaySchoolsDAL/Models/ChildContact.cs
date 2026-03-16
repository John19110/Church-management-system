using SunDaySchools.DAL.Models;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;

public class ChildContact : SchoolEntity
{
    public int Id { get; set; }
    public string? Relation { get; set; }
    public string? PhoneNumber { get; set; } 
    public List<PhoneCall>? CallsHistory { get; set; }

    // Foreign Key
    public int ChildId { get; set; }
    public Child Child { get; set; }   // Navigation property
}
