using Church.DAL.Models;
using Church.Domain;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Church.DAL.Repository.Interfaces
{
    public interface IMeetingRepository
    {
        Task<IQueryable<Meeting>> GetAllAsync();
        /// <summary>Tenant-scoped lookup. Returns null for meetings outside the caller's church.</summary>
        Task<Meeting?> GetByIdAsync(int id);

        /// <summary>
        /// Tenant-unscoped lookup for anonymous self-registration only, where the meeting was
        /// already identified by its public join code and no tenant exists yet.
        /// </summary>
        Task<Meeting?> GetByIdUnscopedAsync(int id);

        Task<Meeting?> GetByPublicIdAsync(string publicId);
        Task<int?> GetMeetingIdByPublicIdAsync(string publicId);
        Task<bool> ExistsPublicIdAsync(string publicId, int? excludeMeetingId = null);
        Task<bool> ExistsPublicIdInChurchAsync(int churchId, string publicId, int? excludeMeetingId = null);
        Task<List<Meeting>> GetMeetingsWithLegacyPublicIdsAsync();
        Task<List<Meeting>> GetMeetingsNeedingShortPublicIdAsync();
        Task<Meeting?> GetByNameAsync(string name);

       Task<List<(int Id, string Name)>> GetMeetingsForSelection();

        Task<List<Meeting>> GetByChurchIdAsync(int id);
        Task AddAsync(Meeting meeting);
        Task UpdateAsync(Meeting meeting);
        Task DeleteAsync(int id);
        Task DeleteWithDependenciesAsync(int id);
    }
}