using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Repository.Implementations;
using SunDaySchools.DAL.Repository.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
namespace SunDaySchools.BLL.Manager.Implementations
{
    public class AttendanceManager:IAttendanceManager
    {


    private readonly IAttendanceRepository _iAttendanceRepository;
    public AttendanceManager(IAttendanceRepository iAttendanceRepository)
    {
        _iAttendanceRepository = iAttendanceRepository;
    }
      public  void TakeAttendance(AttendanceSession session)
    {

    }
    public    void EditAttendance(AttendanceSession session)
    {

    }

}
}
