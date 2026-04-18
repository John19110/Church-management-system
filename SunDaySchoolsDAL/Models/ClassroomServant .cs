using SunDaySchools.DAL.Models;
using SunDaySchools.Models;

public class ClassroomServant : ChurchEntity, SunDaySchoolsDAL.Models.IClassroomScoped
{
    public int ServantId { get; set; }
    public Servant Servant { get; set; } = default!;

    public int ClassroomId { get; set; }
    public Classroom Classroom { get; set; } = default!;
}