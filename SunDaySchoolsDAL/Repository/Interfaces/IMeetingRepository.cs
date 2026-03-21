using SunDaySchools.DAL.Models;
using SunDaySchoolsDAL.DBcontext;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public interface IMeetingRepository
    {

            public IQueryable<Meeting> GetAll();
            public Meeting? GetById(int id);

            public void Add(Meeting meeting);
            public void Update(Meeting meeting);
            public void Delete(int id) ;





        }
    }

