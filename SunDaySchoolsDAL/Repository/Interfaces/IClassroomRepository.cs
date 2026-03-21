using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public interface IClassroomRepository
    {

        public IQueryable<Classroom> GetAll();
        public Classroom? GetById(int id);
        public void Add(Classroom classroom);
        public void Update(Classroom classroom);
        public void Delete(int id);
            

        }
    }






