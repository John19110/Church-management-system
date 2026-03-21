using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface ISuperAdminManager
    {

        Task<List<PendingServantDTO>> GetPendingAdmins();



    }
}
