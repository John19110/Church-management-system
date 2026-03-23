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



        Task UpdateAsync(Servant servant);

        Task DeleteAsync(int id);
    }
}