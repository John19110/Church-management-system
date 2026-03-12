using SunDaySchools.DAL.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public interface IAttendanceRepository
    {
        Task  TakeAttendance(AttendanceSession session);
        Task  EditAttendance(AttendanceSession session);
        Task<AttendanceSession> GetAttendance(int SessionId);

    }
}
