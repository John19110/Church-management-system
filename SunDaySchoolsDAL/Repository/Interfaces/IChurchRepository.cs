using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public  interface IChurchRepository
    {
        Task AddAsync(Church church);

        Task<Church?> GetByNameAsync(string churchName);
        Task<Church?> GetByIdAsync(int ChurchId);
        Task UpdateAsync(Church church);

    }
}
