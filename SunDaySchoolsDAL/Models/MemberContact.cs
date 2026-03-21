using SunDaySchools.DAL.Models;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;

public class MemberContact : ChurchEntity
{
    public int Id { get; set; }
    public string? Relation { get; set; }
    public string? PhoneNumber { get; set; } 
    public List<PhoneCall>? CallsHistory { get; set; }

    // Foreign Key
    public int MemberId { get; set; }
    public Member Member { get; set; }   // Navigation property
}
