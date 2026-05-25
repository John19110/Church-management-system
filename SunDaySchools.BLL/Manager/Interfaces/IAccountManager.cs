using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SunDaySchools.BLL.DTOS.AccountDtos;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface IAccountManager
    {
        Task<AuthFlowResultDto> Login(LoginDTO loginDto);

        Task<AuthFlowResultDto> RegisterServant(RegisterServantDTO dto, string webRootPath);
        Task<AuthFlowResultDto> RegisterChurchSuperAdmin(RegisterChurchAdminDTO dto, string webRootPath);
        Task<AuthFlowResultDto> RegisterMeetingAdminNewChurch(RegisterMeetingAdminNewChurchDTO dto, string webRootPath);

        //    Task<string> RegisterMeetingAdminExistingChurch(RegisterMeetingAdminExistingChurch registerDTO);

    }
}