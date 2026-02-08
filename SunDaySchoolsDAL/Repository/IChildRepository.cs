using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchoolsDAL.Repository
{
    public interface IChildRepository
    {
        IQueryable<Child> GetAll();
        
        Child GetById(int id);
        void Add(Child child);
        void Update(Child child);
        void Delete(int id);


    }
}
