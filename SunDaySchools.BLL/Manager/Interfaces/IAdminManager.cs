using SunDaySchools.BLL.DTOS;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface IAdminManager
    {
        void AssignClassToServant(int ServantId, int ClassroomId);

        void AddServant(ServantAddDTO servant);

        Task<List<PendingServantDTO>> GetPendingServants();

        Task ApproveServant(string userId);

        Task RejectServant(string userId);
    }
}