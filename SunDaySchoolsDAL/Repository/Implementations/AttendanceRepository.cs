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

        public async Task Edit(AttendanceSession session)
        {
            _context.AttendanceSessions.Update(session);
            await _context.SaveChangesAsync();
        }

        public async Task Take(AttendanceSession session)
        {
            foreach (var record in session.Records)
            {
                if (record.Status != AttendanceStatus.Absent)
                {
                    var member = await _context.Members
                        .FirstOrDefaultAsync(c => c.Id == record.MemberId);

                    if (member != null)
                    {
                        member.TotalNumberOfDaysAttended++;

                        // Convert session.CreatedAt (DateTime) to DateOnly for comparison

                        // Only update LastAttendanceDate if this session date is more recent
                        if (session.CreatedAt > member.LastAttendanceDate)
                            member.LastAttendanceDate = session.CreatedAt;
                    }
                }
            }

            await _context.AttendanceSessions.AddAsync(session);
            await _context.SaveChangesAsync();
        }
        public async Task<AttendanceSession> Get(int  SessionId)
        {
             return  _context.AttendanceSessions
                .Include(c=>c.Records)
                    .ThenInclude(r => r.Member)
                .FirstOrDefault(c => c.Id == SessionId);
            
        }

        public async Task<List<AttendanceSession>> GetByClassroom(int classroomId)
        {
            return await _context.AttendanceSessions
                .AsNoTracking()
                .Where(s => s.ClassroomId == classroomId)
                .Include(s => s.Records)
                    .ThenInclude(r => r.Member)
                .OrderByDescending(s => s.CreatedAt)
                .ToListAsync();
        }





    }
}