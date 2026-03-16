using  Microsoft.AspNetCore.Identity;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;
using System.Security;
using System.Text;
using System.Threading.Tasks;
using static System.Runtime.InteropServices.JavaScript.JSType;
namespace SunDaySchoolsDAL.Models
{
    public class ApplicationUser : IdentityUser
    {
        public Servant? ServantProfile { get; set; } // navigation only
                                                     //the ? means that not all the user should be servants they may be admin only 
        public int SchoolId { get; set; }


        // Servant table = servant data such as classroom, phone calls, attendance work, etc.

        // Servant role = permission to access servant endpoints/pages

        // Admin role = permission to access admin endpoints/pages

    }
}
