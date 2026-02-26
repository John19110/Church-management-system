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
       Task< AttendanceSession>  TakeAttendance(AttendanceSession session);
        Task<AttendanceSession> EditAttendance(AttendanceSession session);

    }
}
