using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.DTOS.AccountDtos
{
    public class RegisterServamtinAddAdmin
    {
        public string Name { get; set; }

        public string PhoneNumber { get; set; }

        public string Password { get; set; }

        public string ConfirmPassword { get; set; }

        // public int    ChurchId { get; set; }
    }
}
