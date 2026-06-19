using SunDaySchools.DAL.Models.CustomFields;
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
        private readonly IMemberRepository _memberRepository;

        public ClassroomRepository(ProgramContext context, IMemberRepository memberRepository)
        {
            _context = context;
            _memberRepository = memberRepository;
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
        public async Task<List<(int Id, string Name)>> GetClassroomsForSelection()
        {
            return await _context.Classrooms
                .AsNoTracking()
                .Select(c => new ValueTuple<int, string>(c.Id, c.Name))
                .ToListAsync();
        }

        public async Task<List<Classroom>> GetByIdsAsync(List<int> ids)
        {
            if (ids == null || ids.Count == 0)
                return new List<Classroom>();

            return await _context.Classrooms
                .AsNoTracking()
                .Where(c => ids.Contains(c.Id))
                .ToListAsync();
        }

        public async Task<Classroom?> GetByIdAsync(int id)
        {
            return await _context.Classrooms
                .Include(c => c.ClassroomServants)
                    .ThenInclude(cs => cs.Servant)
                .Include(c => c.Members)
                .Include(c => c.AttendanceHistory)
                .Include(c => c.LeaderServant)
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
            await DeleteWithDependenciesAsync(id);
        }

        public async Task DeleteWithDependenciesAsync(int id)
        {
            await using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                await DeleteWithDependenciesCoreAsync(id);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }

        public async Task DeleteWithDependenciesCoreAsync(int id)
        {
            await _memberRepository.DeleteByClassroomIdAsync(id);

            var sessionIds = await _context.AttendanceSessions
                .IgnoreQueryFilters()
                .Where(s => s.ClassroomId == id)
                .Select(s => s.Id)
                .ToListAsync();

            if (sessionIds.Count > 0)
            {
                await _context.AttendanceRecords
                    .IgnoreQueryFilters()
                    .Where(r => sessionIds.Contains(r.AttendanceSessionId))
                    .ExecuteDeleteAsync();

                await _context.AttendanceSessions
                    .IgnoreQueryFilters()
                    .Where(s => s.ClassroomId == id)
                    .ExecuteDeleteAsync();
            }

            var examIds = await _context.Exams
                .IgnoreQueryFilters()
                .Where(e => e.ClassroomId == id)
                .Select(e => e.Id)
                .ToListAsync();

            if (examIds.Count > 0)
            {
                await _context.ExamResults
                    .IgnoreQueryFilters()
                    .Where(er => examIds.Contains(er.ExamId))
                    .ExecuteDeleteAsync();

                await _context.Exams
                    .IgnoreQueryFilters()
                    .Where(e => e.ClassroomId == id)
                    .ExecuteDeleteAsync();
            }

            await _context.ClassroomServants
                .IgnoreQueryFilters()
                .Where(cs => cs.ClassroomId == id)
                .ExecuteDeleteAsync();

            await _context.CustomFieldValues
                .IgnoreQueryFilters()
                .Where(v =>
                    v.EntityName == CustomFieldEntityNames.Classroom &&
                    v.EntityId == id)
                .ExecuteDeleteAsync();

            await _context.Classrooms
                .IgnoreQueryFilters()
                .Where(c => c.Id == id)
                .ExecuteUpdateAsync(s => s.SetProperty(c => c.LeaderServantId, (int?)null));

            var classroom = await _context.Classrooms
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(c => c.Id == id);

            if (classroom == null)
                return;

            _context.Classrooms.Remove(classroom);
        }

        public async Task<List<Classroom>> GetByServantIdAsync(int? servantId)
        {
            if (!servantId.HasValue)
                return new List<Classroom>();

            return await GetAccessibleForServantAsync(servantId.Value);
        }

        public async Task<List<Classroom>> GetAccessibleForServantAsync(int servantId)
        {
            return await _context.Classrooms
                .Where(c =>
                    c.ClassroomServants.Any(cs => cs.ServantId == servantId) ||
                    c.LeaderServantId == servantId)
                .Include(c => c.Members)
                .Include(c => c.AttendanceHistory)
                .Include(c => c.ClassroomServants)
                    .ThenInclude(cs => cs.Servant)
                .Include(c => c.LeaderServant)
                .ToListAsync();
        }

        public async Task<List<int>> GetAccessibleClassroomIdsForServantAsync(int servantId)
        {
            var fromJunction = await _context.ClassroomServants
                .AsNoTracking()
                .Where(cs => cs.ServantId == servantId)
                .Select(cs => cs.ClassroomId)
                .ToListAsync();

            var fromLeader = await _context.Classrooms
                .AsNoTracking()
                .Where(c => c.LeaderServantId == servantId)
                .Select(c => c.Id)
                .ToListAsync();

            return fromJunction.Concat(fromLeader).Distinct().ToList();
        }

        public async Task<List<Classroom>> GetByMeetingIdAsync(int? meetingId)
        {
            return await _context.Classrooms
                .Where(c => c.MeetingId == meetingId)
                .Include(c => c.Members)
                .Include(c => c.AttendanceHistory)
                .Include(c => c.ClassroomServants)
                    .ThenInclude(cs => cs.Servant)
                .Include(c => c.LeaderServant)
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
                .Include(c => c.LeaderServant)
                .ToListAsync();
        }

        public async Task<bool> IsServantAssignedAsync(int servantId, int classroomId)
        {
            return await _context.Classrooms
                .AnyAsync(c =>
                    c.Id == classroomId &&
                    (c.ClassroomServants.Any(cs => cs.ServantId == servantId) ||
                     c.LeaderServantId == servantId));
        }
        public async Task SaveAsync()
        {
            await _context.SaveChangesAsync();
        }

    }
}