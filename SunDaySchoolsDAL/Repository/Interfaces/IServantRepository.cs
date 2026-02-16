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

        Servant GetById(int id);
        void Add(Servant servant);
        void Update(Servant servant);
        void Delete(int id);




    }
}
