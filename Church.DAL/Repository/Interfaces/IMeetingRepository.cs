using Church.DAL.Models;
using Church.Domain;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Church.DAL.Repository.Interfaces
{
    public interface IMeetingRepository
    {
        Task<IQueryable<Meeting>> GetAllAsync();
        Task<Meeting?> GetByIdAsync(int id);
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