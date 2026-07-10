using Church.BLL.DTOS.Meeting;
using Church.BLL.DTOS.AccountDtos;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Church.BLL.Manager.Interfaces
{
    public interface IAdminManager
    {
        Task AssignClassToServant(int ServantId, int ClassroomId);

        Task<List<PendingServantDTO>> GetPendingServants();

        Task ApproveServant(string userId);

        Task RejectServant(string userId);

        /// <summary>Pending users who registered with this Meeting Admin's public Meeting ID.</summary>
        Task<List<PendingUserDTO>> GetPendingUsers();

        Task ApproveUser(string userId, int? meetingId);

        Task RejectUser(string userId, string? reason);


    }
}