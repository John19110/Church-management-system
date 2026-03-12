using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace SunDaySchools.DAL.Repository.Implementations
{
    public class AdminRepository: IAdminRepository
    {

        private readonly ProgramContext _context;
        public AdminRepository(ProgramContext context)
        {
            _context = context;

        }
       public (Servant? servant,Classroom? classroom) AssignClassToServant(int ServantId,int ClassroomId)
        {
            var servant = _context.Servants.FirstOrDefault(p => p.Id ==ServantId);
             var classroom = _context.Classrooms
                                     .Include(c => c.Servants)
                                     .FirstOrDefault(c => c.Id == ClassroomId);
            return (servant, classroom);

        }

        public void Save()
        {
            _context.SaveChanges();
        }



    }
}
