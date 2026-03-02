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
        void TakeAttendance(AttendanceSessionAddDTO session);
        void EditAttendance(AttendanceSessionUpdateDTO session);

        AttendanceSession GetAttendance(int sessionId);
    }
}
