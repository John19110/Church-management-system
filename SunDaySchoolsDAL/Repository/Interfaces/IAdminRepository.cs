using SunDaySchools.DAL.Models;
using SunDaySchools.Models;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public interface IAdminRepository
    {
        Task<(Servant? servant, Classroom? classroom)> AssignClassToServantAsync(int servantId, int classroomId);

        // AddServantAsync(Servant servant);

        Task SaveAsync();
    }
}