using SunDaySchools.DAL.Models;
using SunDaySchools.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public interface IMeetingRepository
    {
        Task<IQueryable<Meeting>> GetAllAsync();
        Task<Meeting?> GetByIdAsync(int id);
        Task<Meeting?> GetByNameAsync(string name);

       Task<List<(int Id, string Name)>> GetMeetingsForSelection();

        Task<List<Meeting>> GetByChurchIdAsync(int id);
        Task AddAsync(Meeting meeting);
        Task UpdateAsync(Meeting meeting);
        Task DeleteAsync(int id);
    }
}