using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchoolsDAL.DBcontext;

namespace SunDaySchools.DAL.Repository.Implementations
{
    public class AdminRepository:IAdminRepository
    {

        private readonly ProgramContext _context;
        public AdminRepository(ProgramContext context)
        {
            _context = context;

        }
        void AssignClassToServant(int ServantId,int ClassId)
        {
            var servant = _context.Servants.FirstOrDefault(p => p.Id ==ServantId);
            if(servant== null)
            {
               // return throw
            }


        }



    }
}
