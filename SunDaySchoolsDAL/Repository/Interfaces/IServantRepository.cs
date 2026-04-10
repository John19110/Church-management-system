using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public interface IServantRepository
    {
        Task<IEnumerable<Servant>> GetAllAsync();

        /// <summary>
        /// Loads by <see cref="Servant.ApplicationUserId"/> ignoring global query filters
        /// so the row is found even when tenant filters would hide it.
        /// </summary>
        Task<Servant?> GetByApplicationUserIdAsync(string applicationUserId);

        /// <summary>
        /// Returns the existing Servant for the user, or creates a minimal row when
        /// <paramref name="autoCreate"/> is true and <see cref="ApplicationUser.ChurchId"/> is set.
        /// </summary>
        Task<Servant?> EnsureServantProfileAsync(ApplicationUser user, bool autoCreate, CancellationToken cancellationToken = default);

        Task<Servant?> GetByIdAsync(int id);

        Task<List<Servant>> GetByIdsAsync(List<int> ids);
        Task<IEnumerable<Classroom>> GetByServantIdAsync(int servantId);

        Task AddAsync(Servant servant);

        Task UpdateAsync(Servant servant);

        Task DeleteAsync(int id);
    }
}