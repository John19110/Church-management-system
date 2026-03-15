using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SunDaySchools.DAL.Models;
using SunDaySchools.Models;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public  interface IAdminRepository
    {
        (Servant? servant, Classroom? classroom) AssignClassToServant(int ServantId,int ClassroomId);

        //   void ApprovServant();
        void AddServant(Servant  servant);

        public void Save();
    }
}
