using SunDaySchools.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public interface IServantRepository
    {
        Task<IEnumerable<Servant>> GetAllAsync();

        Task<Servant?> GetByApplicationUserIdAsync(string applicationUserId);

        Task<Servant?> GetByIdAsync(int id);

        Task<List<Servant>> GetByIdsAsync(List<int> ids);
        Task<IEnumerable<Classroom>> GetByServantIdAsync(int servantId);

        Task AddAsync(Servant servant);

        Task UpdateAsync(Servant servant);

        /// <summary>Removes the servant if it exists. Returns <c>true</c> if a row was deleted, <c>false</c> if none matched.</summary>
        Task<bool> DeleteAsync(int id);
    }
}