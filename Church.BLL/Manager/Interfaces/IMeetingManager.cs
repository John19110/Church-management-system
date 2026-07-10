using Church.BLL.DTOS;
using Church.BLL.DTOS.Meeting;
using Church.BLL.DTOS.MeetingDtos;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Church.BLL.Manager.Interfaces
{
    public interface IMeetingManager
    {

        Task AddMeeting(MeetingAddDTO meeting);

        Task<List<SelectOptionDTO>> GetMeetingsForSelection();
        Task<List<MeetingReadDTO>> GetVisibleMeetings();

        Task UpdateMeeting(int id, MeetingUpdateDto dto, bool generateDefaults = false);
        Task DeleteMeetingAsync(int id);

    }
}
