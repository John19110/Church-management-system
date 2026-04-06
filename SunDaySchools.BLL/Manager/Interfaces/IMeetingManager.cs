using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.MeetingDtos;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface IMeetingManager
    {
       Task<List<SelectOptionDTO>> GetMeetingsForSelection();
        Task<List<MeetingReadDTO>> GetVisibleMeetings();


    }
}
