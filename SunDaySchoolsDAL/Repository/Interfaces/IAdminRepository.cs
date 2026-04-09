using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Models;
using SunDaySchools.Models;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public interface IAdminRepository
    {
      //  Task<(Servant? servant, Classroom? classroom)> AssignClassToServantAsync(int servantId, int classroomId);

        Task<bool> ClassroomServantExistsAsync(int servantId, int classroomId);

        Task<(Servant servant, Classroom classroom)> GetServantAndClassroomAsync(int servantId, int classroomId);

        Task AddClassroomServantAsync(ClassroomServant entity);
        Task SaveAsync();
    }
}