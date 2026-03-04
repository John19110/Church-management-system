using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchoolsDAL.DBcontext;

namespace SunDaySchools.DAL.Repository.Implementations
{
    public class AttendanceRepository : IAttendanceRepository
    {
        private readonly ProgramContext _context;

        public AttendanceRepository(ProgramContext context)
        {
            _context = context;
        }

        public async Task EditAttendance(AttendanceSession session)
        {
            _context.AttendanceSessions.Update(session);
            await _context.SaveChangesAsync();
        }

        public async Task TakeAttendance(AttendanceSession session)
        {
            foreach (var record in session.Records)
            {
                if (record.Status != AttendanceStatus.Absent)
                {
                    var child = await _context.Children
                        .FirstOrDefaultAsync(c => c.Id == record.ChildId);

                    if (child != null)
                    {
                        child.TotalNumberOfDaysAttended++;
                        if (child.LastAttendanceDate < session.CreatedAtUtc)
                            child.LastAttendanceDate = session.CreatedAtUtc;

                    }
                }
            }

            await _context.AttendanceSessions.AddAsync(session);
            await _context.SaveChangesAsync();
        }

        public async Task<AttendanceSession> GetAttendance(int  SessionId)
        {
             return  _context.AttendanceSessions.Include(c=>c.Records)
                .FirstOrDefault(c => c.Id == SessionId);
            
        }





    }
}