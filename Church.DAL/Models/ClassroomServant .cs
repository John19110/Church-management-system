using Church.DAL.Models;
using Church.Domain;

public class ClassroomServant : ChurchEntity, Church.DAL.Models.IClassroomScoped
{
    public int ServantId { get; set; }
    public Servant Servant { get; set; } = default!;

    public int ClassroomId { get; set; }
    public Classroom Classroom { get; set; } = default!;
}