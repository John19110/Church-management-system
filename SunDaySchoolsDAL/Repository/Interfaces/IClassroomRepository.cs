using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public interface IClassroomRepository
    {
        Task<IQueryable<Classroom>> GetAllAsync(); 
        Task<Classroom?> GetByIdAsync(int id);
        Task<bool> ExistsAsync(int id);
        Task AddAsync(Classroom classroom);
        Task UpdateAsync(Classroom classroom);
        Task DeleteAsync(int id);
        Task DeleteWithDependenciesAsync(int id);

        /// <summary>
        /// Cascade delete classroom dependents without opening a transaction.
        /// Caller must invoke <see cref="ProgramContext.SaveChangesAsync"/> within its unit of work.
        /// </summary>
        Task DeleteWithDependenciesCoreAsync(int id);

        Task<List<Classroom>> GetByServantIdAsync(int? servantId);
        /// <summary>Classrooms assigned via junction or as designated leader.</summary>
        Task<List<Classroom>> GetAccessibleForServantAsync(int servantId);
        Task<List<int>> GetAccessibleClassroomIdsForServantAsync(int servantId);
        Task<List<Classroom>> GetByMeetingIdAsync(int? meetingId);
        Task<List<Classroom>> GetByChurchIdAsync(int? churchId);

        Task<bool> IsServantAssignedAsync(int servantId, int classroomId);
        Task SaveAsync();


        Task<List<(int Id, string Name)>> GetClassroomsForSelection();

        Task<List<Classroom>> GetByIdsAsync(List<int> ids);
    }
}