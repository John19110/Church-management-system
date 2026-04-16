using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface IServantManager
    {
        Task<IEnumerable<ServantReadDTO>> GetAllAsync();

        Task AddAsync(AdminAddServantDTO servantDto, string webRootPath);
        Task<ServantReadDTO?> GetByIdAsync(int id);

        Task<List<SelectOptionDTO>> GetServantsForSelection();

        Task UpdateAsync(ServantUpdateDTO servant);

        /// <summary>Returns <c>true</c> if the servant existed and was deleted; <c>false</c> if no matching servant.</summary>
        Task<bool> DeleteAsync(int id);
    }
}