using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Models
{
    public abstract class ChurchEntity
    {
        public int? ChurchId { get; set; }
        public Church? Chuch { get; set; }

        public int MeetingId { get; set; }
        public Meeting meeting { get; set; }




    }
}
