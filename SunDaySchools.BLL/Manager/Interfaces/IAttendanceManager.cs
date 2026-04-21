using SunDaySchools.DAL.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SunDaySchools.BLL.DTOS;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface IAttendanceManager
    {
        Task TakeAttendanceAsync(AttendanceSessionAddDTO session);

        Task EditAttendanceAsync(AttendanceSessionUpdateDTO session);

        Task<AttendanceSessionReadDTO?> GetAttendanceAsync(int sessionId);

        Task<List<AttendanceSessionSummaryDTO>> GetHistoryByClassroomAsync(int classroomId);
    }
}
