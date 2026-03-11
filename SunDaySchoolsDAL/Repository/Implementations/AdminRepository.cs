using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchoolsDAL.DBcontext;
using SunDaySchools.DAL.Models;
using SunDaySchools.Models;


namespace SunDaySchools.DAL.Repository.Implementations
{
    public class AdminRepository: IAdminRepository
    {

        private readonly ProgramContext _context;
        public AdminRepository(ProgramContext context)
        {
            _context = context;

        }
       public (Servant?,Classroom?) AssignClassToServant(int ServantId,int ClassroomId)
        {
            var servant = _context.Servants.FirstOrDefault(p => p.Id ==ServantId);
            var classroom = _context.Classrooms.FirstOrDefault(p => p.Id == ClassroomId);
            return (servant, classroom);

        }



    }
}
