using SunDaySchools.DAL.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface IAttendanceManager
    {
        AttendanceSession TakeAttendance(AttendanceSession session);
        AttendanceSession EditAttendance(AttendanceSession session);
    }
}
