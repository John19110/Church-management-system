using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchoolsDAL.DBcontext;

namespace SunDaySchools.DAL.Repository.Implementations
{
    public class AttendanceRepository : IAttendanceRepository
    {

        private readonly ProgramContext _context;
        public AttendanceRepository(ProgramContext context )
        {
            _context = context; 

        }
     public   void TakeAttendance(AttendanceSession session)
        {
                _context.AttendanceSessions.Add(session);
            
        }
      public  void EditAttendance(AttendanceSession session)

        {

                        _context.AttendanceSessions.Update(session);


        }

}
}
