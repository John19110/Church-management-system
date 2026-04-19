using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Models
{
    public class Meeting 
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public int ChurchId { get; set; }

        
        public TimeOnly Weekly_appointment { get; set; }
        public string DayOfWeek { get; set; } = string.Empty;
        public Church? Church { get; set; }
        public ICollection<Servant> Servants { get; set; } = new List<Servant>();
        public ICollection<Member> Members { get; set; } = new List<Member>();

        public int? LeaderServantId { get; set; }  // Nullable if a meeting may not have a leader yet
        public Servant? LeaderServant { get; set; }



    }
}
