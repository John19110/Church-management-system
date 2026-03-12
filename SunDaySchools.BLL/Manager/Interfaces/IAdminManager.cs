using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SunDaySchoolsDAL.Models;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface IAdminManager
    {
       void AssignClassToServant(int ServantId, int ClassroomId);


    }
}
