using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Models
{
    public class Meeting : ChurchEntity
    {
        public int Id { get; set; }
        public string? Name { get; set; }

        public ICollection<Servant>? Servants { get; set; }

        public ICollection<Member>? Members { get; set; }
             




    }
}
