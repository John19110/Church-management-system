using Church.BLL.DTOS;
using Church.BLL.DTOS.AccountDtos;
using Church.Domain;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Church.BLL.Manager.Interfaces
{
    public interface IServantManager
    {
        Task<IEnumerable<ServantReadDTO>> GetAllAsync();

        Task<IEnumerable<ServantReadDTO>> GetByMeetingIdAsync(int meetingId);

        Task AddAsync(AdminAddServantDTO servantDto, string webRootPath);
        Task<ServantReadDTO?> GetByIdAsync(int id);

        /// <summary>
        /// Ensures the caller may read the servant (meeting isolation for Servant role).
        /// </summary>
        Task EnsureCanViewServantAsync(int servantId);

        /// <summary>
        /// Ensures the caller may modify the servant (Servant role: own profile only).
        /// </summary>
        Task EnsureCanModifyServantAsync(int servantId);

        Task<List<SelectOptionDTO>> GetServantsForSelection();

        Task UpdateAsync(ServantUpdateDTO servant);

        /// <summary>Returns <c>true</c> if the servant existed and was deleted; <c>false</c> if no matching servant.</summary>
        Task<bool> DeleteAsync(int id);
    }
}