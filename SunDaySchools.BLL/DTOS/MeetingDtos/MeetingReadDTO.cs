using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.DTOS.MeetingDtos
{
    public class MeetingReadDTO
    {

            public string? Name { get; set; }
            public DateTime Weekly_appointment { get; set; }
            public ICollection<Servant>? Servants { get; set; }
            public ICollection<Member>? Members { get; set; }
        public int? LeaderServantId { get; set; }  // Nullable if a meeting may not have a leader yet



    }
}

