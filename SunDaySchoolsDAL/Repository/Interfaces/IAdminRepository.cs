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
        (Servant,Classroom) AssignClassToServant();

        void ApprovServant();


    }
}
