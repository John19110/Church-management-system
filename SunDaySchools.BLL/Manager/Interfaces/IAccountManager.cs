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
        Task<string> Login(LoginDTO loginDto);

        Task<string> RegisterServant(RegisterServantDTO dto, string webRootPath);
        Task<string> RegisterChurchSuperAdmin(RegisterChurchAdminDTO dto, string webRootPath);
        Task<string> RegisterMeetingAdminNewChurch(RegisterMeetingAdminNewChurchDTO dto, string webRootPath);

        //    Task<string> RegisterMeetingAdminExistingChurch(RegisterMeetingAdminExistingChurch registerDTO);

    }
}