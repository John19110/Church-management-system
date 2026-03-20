using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public interface IServantRepository
    {
        IQueryable<Servant> GetAll();

        Task<Servant?> GetByApplicationUserIdAsync(string applicationUserId);

       Task< Servant?> GetById(int id);

        // void Add(Servant servant);

        Task<IEnumerable<Classroom>> GetByServantIdAsync(int servantId);

        Task  Update(Servant servant);
        void Delete(int id);

    }
}
