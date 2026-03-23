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
        Task<IQueryable<Classroom>> GetAllAsync(); // Or perhaps Task<List<Classroom>>? IQueryable might be tricky with async, but it's possible.
        Task<Classroom?> GetByIdAsync(int id);
        Task AddAsync(Classroom classroom);
        Task UpdateAsync(Classroom classroom);
        Task DeleteAsync(int id);

        Task<List<Classroom>> GetByServantIdAsync(int? servantId);
        Task<List<Classroom>> GetByMeetingIdAsync(int? meetingId);
        Task<List<Classroom>> GetByChurchIdAsync(int? churchId);



    }
}