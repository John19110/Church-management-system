using  Microsoft.AspNetCore.Identity;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
namespace SunDaySchoolsDAL.Models
{
    public class ApplicationUser : IdentityUser
    {
        public Servant? ServantProfile { get; set; } // navigation only

    }
}
