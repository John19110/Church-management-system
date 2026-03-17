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
        public Task<string> RegisterChurchAdmin(RegisterChurchAdminDTO registerChurchAdminDTO);
        public Task<string> RegisterServant(RegisterServantDTO registerDto);




    }
}
