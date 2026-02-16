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
        void TakeAttendance(AttendanceSession session);
        void EditAttendance(AttendanceSession session);
    }
}
