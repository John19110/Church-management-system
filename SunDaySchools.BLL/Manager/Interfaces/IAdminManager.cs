using SunDaySchools.BLL.DTOS;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface IAdminManager
    {
       void AssignClassToServant(int ServantId, int ClassroomId);
        void AddServant(ServantAddDTO servant);


    }
}
