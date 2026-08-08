using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Church.DAL.Repository.Interfaces
{
    public  interface IChurchRepository
    {
        Task AddAsync(ChurchModel church);

        Task<ChurchModel?> GetByNameAsync(string churchName);

        /// <summary>Tenant-scoped lookup. Returns null for churches outside the caller's tenant.</summary>
        Task<ChurchModel?> GetByIdAsync(int ChurchId);

        /// <summary>
        /// Tenant-unscoped lookup for anonymous self-registration only, where the church was
        /// already identified by its public join code and no tenant exists yet.
        /// </summary>
        Task<ChurchModel?> GetByIdUnscopedAsync(int churchId);
        Task<ChurchModel?> GetByPublicIdAsync(string publicId);
        Task<int?> GetChurchIdByPublicIdAsync(string publicId);
        Task<bool> ExistsPublicIdAsync(string publicId, int? excludeChurchId = null);
        Task<List<ChurchModel>> GetChurchesNeedingShortPublicIdAsync();
        Task UpdateAsync(ChurchModel church);

    }
}
