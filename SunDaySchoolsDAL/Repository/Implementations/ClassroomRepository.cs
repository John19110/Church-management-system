using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Repository.Implementations
{
    public class ClassroomRepository : IClassroomRepository
    {
        private readonly ProgramContext _context;

        public ClassroomRepository(ProgramContext context)
        {
            _context = context;
        }

        public async Task<IQueryable<Classroom>> GetAllAsync()
        {
            return await Task.FromResult(
                _context.Classrooms
                    .Include(c => c.ClassroomServants)
                        .ThenInclude(cs => cs.Servant)
                    .Include(c => c.Members)
                    .Include(c => c.AttendanceHistory)
            );
        }

        public async Task<Classroom?> GetByIdAsync(int id)
        {
            return await _context.Classrooms
                //.Include(c => c.Servants)
                .Include(c => c.Members)
                .Include(c => c.AttendanceHistory)
                .FirstOrDefaultAsync(s => s.Id == id);
        }

        public async Task<bool> ExistsAsync(int id)
        {
            return await _context.Classrooms.AnyAsync(c => c.Id == id);
        }

        public async Task AddAsync(Classroom classroom)
        {
            await _context.Classrooms.AddAsync(classroom);
            await _context.SaveChangesAsync();
        }

        public async Task UpdateAsync(Classroom classroom)
        {
            // No need to attach if the entity is already tracked.
            _context.Classrooms.Update(classroom);
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(int id)
        {
            var classroom = await _context.Classrooms.FindAsync(id);
            if (classroom != null)
            {
                _context.Classrooms.Remove(classroom);
                await _context.SaveChangesAsync();
            }
        }

        public async Task<List<Classroom>> GetByServantIdAsync(int? servantId)
        {
            if (!servantId.HasValue)
                return new List<Classroom>();

            return await _context.Classrooms
                .Where(c => c.ClassroomServants.Any(cs => cs.ServantId == servantId.Value))
                .Include(c => c.Members)
                .Include(c => c.AttendanceHistory)
                .Include(c => c.ClassroomServants)
                    .ThenInclude(cs => cs.Servant)
                .ToListAsync();
        }

        public async Task<List<Classroom>> GetByMeetingIdAsync(int? meetingId)
        {
            return await _context.Classrooms
                .Where(c => c.MeetingId == meetingId)
                .Include(c => c.Members)
                .Include(c => c.AttendanceHistory)
                .Include(c => c.ClassroomServants)
                    .ThenInclude(cs => cs.Servant)
                .ToListAsync();
        }

        public async Task<List<Classroom>> GetByChurchIdAsync(int? churchId)
        {
            return await _context.Classrooms
                .Where(c => c.ChurchId == churchId)
                .Include(c => c.Members)
                .Include(c => c.AttendanceHistory)
                .Include(c => c.ClassroomServants)
                    .ThenInclude(cs => cs.Servant)
                .ToListAsync();
        }

        public async Task<bool> IsServantAssignedAsync(int servantId, int classroomId)
        {
            return await _context.Set<ClassroomServant>()
                .AnyAsync(cs => cs.ServantId == servantId && cs.ClassroomId == classroomId);
        }
        public async Task SaveAsync()
        {
            await _context.SaveChangesAsync();
        }

    }
}