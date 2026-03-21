using SunDaySchools.BLL.DTOS;
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

        Task<ServantReadDTO?> GetByIdAsync(int id);

        Task UpdateAsync(ServantUpdateDTO servant);

        Task DeleteAsync(int id);
    }
}