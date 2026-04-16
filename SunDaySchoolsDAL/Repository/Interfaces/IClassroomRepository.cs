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

        Task<List<Classroom>> GetByServantIdAsync(int? servantId);
        Task<List<Classroom>> GetByMeetingIdAsync(int? meetingId);
        Task<List<Classroom>> GetByChurchIdAsync(int? churchId);

        Task<bool> IsServantAssignedAsync(int servantId, int classroomId);
        Task SaveAsync();



    }
}