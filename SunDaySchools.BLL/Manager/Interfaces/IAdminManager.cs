using SunDaySchools.BLL.DTOS.Meeting;
using SunDaySchools.BLL.DTOS.AccountDtos;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface IAdminManager
    {
        Task AssignClassToServant(int ServantId, int ClassroomId);

        Task<List<PendingServantDTO>> GetPendingServants();

        Task ApproveServant(string userId);

        Task RejectServant(string userId);


    }
}