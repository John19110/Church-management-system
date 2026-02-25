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
        public async Task<AttendanceSession> TakeAttendanceAsync(AttendanceSession session)
        {
            await _context.AttendanceSessions.AddAsync(session);
            await _context.SaveChangesAsync();
            return session;
        }



        public  AttendanceSession EditAttendance(AttendanceSession session)
        {
            _context.AttendanceSessions.Update(session);
            _context.SaveChanges();

            return session;
        }

       
    }
}
