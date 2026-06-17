using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SunDaySchools.BLL.DTOS.AccountDtos;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface ISuperAdminManager
    {

        Task<List<PendingServantDTO>> GetPendingAdmins();

        Task ApproveAdmin(string userId);


        Task RejectAdmin(string userId);

        // ---- Church user approval workflow (Super Admin controlled) ----

        /// <summary>All Pending users (any role) requesting access to the Super Admin's church.</summary>
        Task<List<PendingUserDTO>> GetPendingUsers();

        /// <summary>
        /// Approves a pending user in the Super Admin's church, assigning a meeting
        /// (required for Servant / Meeting Admin) and activating their access.
        /// </summary>
        Task ApproveUser(string userId, int? meetingId);

        /// <summary>Rejects a pending user in the Super Admin's church with an optional reason.</summary>
        Task RejectUser(string userId, string? reason);

    }
}
