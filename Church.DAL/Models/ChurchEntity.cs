using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Church.DAL.Models
{
    public abstract class ChurchEntity
    {
        public int? ChurchId { get; set; }
        public ChurchModel? Church { get; set; }

        public int? MeetingId { get; set; }
        public Meeting? Meeting { get; set; }




    }
}
