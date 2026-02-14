using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.DTOS.AccountDtos
{
    public class RegisterDTO
    {
        public String Name { get; set; }
        public String PhoneNumber { get; set; }
        public String Password { get; set; }
        public string ConfirmPassword { get; set; }



    }
}
