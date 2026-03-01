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
        AttendanceSession TakeAttendance(AttendanceSessionAddDTO session);
        AttendanceSession EditAttendance(AttendanceSessionUpdateDTO session);

        AttendanceSession GetAttendance(int sessionId);
    }
}
