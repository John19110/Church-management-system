using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Church.BLL.DTOS.AccountDtos;

namespace Church.BLL.Manager.Interfaces
{
    public interface IAccountManager
    {
        Task<AuthFlowResultDto> Login(LoginDTO loginDto);

        Task<AuthFlowResultDto> RegisterServant(RegisterServantDTO dto, string webRootPath);

        /// <summary>
        /// Authenticated tenant flow: resolves church/meeting from internal integer IDs (JWT scope).
        /// </summary>
        Task<AuthFlowResultDto> RegisterServantForTenant(
            RegisterServantDTO dto,
            int churchId,
            int meetingId,
            string webRootPath);
        Task<AuthFlowResultDto> RegisterChurchSuperAdmin(RegisterChurchAdminDTO dto, string webRootPath);
        Task<AuthFlowResultDto> RegisterMeetingAdminNewChurch(RegisterMeetingAdminNewChurchDTO dto, string webRootPath);

        //    Task<string> RegisterMeetingAdminExistingChurch(RegisterMeetingAdminExistingChurch registerDTO);

    }
}