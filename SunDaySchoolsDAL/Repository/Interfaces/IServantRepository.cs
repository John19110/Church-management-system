using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public interface IServantRepository
    {
        Task<IEnumerable<Servant>> GetAllAsync();

        Task<Servant?> GetByApplicationUserIdAsync(string applicationUserId);

        /// <summary>
        /// Ensures a <c>Servant</c> profile exists for the given user.
        /// If <paramref name="autoCreateMissing"/> is true, a minimal profile is created and returned.
        /// Returns <c>null</c> if missing and auto-create is disabled.
        /// </summary>
        Task<Servant?> EnsureServantProfileAsync(ApplicationUser user, bool autoCreateMissing);

        /// <summary>Whether a <c>Servants</c> row exists for this user (ignores tenant query filters for integrity checks).</summary>
        Task<bool> HasServantProfileLinkedAsync(string applicationUserId);

        Task<Servant?> GetByIdAsync(int id);

        Task<List<Servant>> GetByIdsAsync(List<int> ids);
        Task<IEnumerable<Classroom>> GetByServantIdAsync(int servantId);
        Task<List<int>> GetClassroomIdsByApplicationUserIdAsync(string applicationUserId);

        Task AddAsync(Servant servant);

        Task UpdateAsync(Servant servant);

        /// <summary>Removes the servant if it exists. Returns <c>true</c> if a row was deleted, <c>false</c> if none matched.</summary>
        Task<bool> DeleteAsync(int id);
    }
}