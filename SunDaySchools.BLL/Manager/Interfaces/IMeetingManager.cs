using SunDaySchools.BLL.DTOS;
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


    }
}
