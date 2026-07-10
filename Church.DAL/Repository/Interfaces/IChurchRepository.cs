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
        Task<ChurchModel?> GetByIdAsync(int ChurchId);
        Task<ChurchModel?> GetByPublicIdAsync(string publicId);
        Task<int?> GetChurchIdByPublicIdAsync(string publicId);
        Task<bool> ExistsPublicIdAsync(string publicId, int? excludeChurchId = null);
        Task<List<ChurchModel>> GetChurchesNeedingShortPublicIdAsync();
        Task UpdateAsync(ChurchModel church);

    }
}
