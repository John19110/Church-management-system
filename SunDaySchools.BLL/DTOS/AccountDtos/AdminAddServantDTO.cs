using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.DTOS.AccountDtos
{
    public class AdminAddServantDTO
    {
       
            public ServantAddDTO Servant { get; set; } = new(); // ✅ prevents null

            public RegisterServamtinAddAdmin Account { get; set; } = new();
        

    }
}
