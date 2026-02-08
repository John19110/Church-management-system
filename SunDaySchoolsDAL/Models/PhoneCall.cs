using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchoolsDAL.Models
{
    public class PhoneCall
    {
        public int Id { get; set; }

        public DateOnly? DateOFthecall;
        public Servant? Servant { get; set; } 
        public string? Notes { get; set; }   
    }
}
