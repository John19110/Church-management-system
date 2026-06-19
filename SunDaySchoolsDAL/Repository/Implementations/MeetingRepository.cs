using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Models.CustomFields;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;

namespace SunDaySchools.DAL.Repository.Implementations
{
    public class MeetingRepository : IMeetingRepository
    {
        private readonly ProgramContext _context;
        private readonly IClassroomRepository _classroomRepository;
        private readonly IMemberRepository _memberRepository;

        public MeetingRepository(
            ProgramContext context,
            IClassroomRepository classroomRepository,
            IMemberRepository memberRepository)
        {
            _context = context;
            _classroomRepository = classroomRepository;
            _memberRepository = memberRepository;
        }

        public async Task<IQueryable<Meeting>> GetAllAsync()
        {
            return await Task.FromResult(
                _context.Meetings
                     .Include(m => m.Servants)
                     .Include(m => m.Members)
            );
        }

        public async Task<List<(int Id, string Name)>> GetMeetingsForSelection()
        {
            return await _context.Meetings
                .AsNoTracking()
                .Select(m => new ValueTuple<int, string>(m.Id, m.Name))
                .ToListAsync();
        }

        public async Task<Meeting?> GetByIdAsync(int id)
        {
            return await _context.Meetings
                .Include(m => m.Servants)
                .Include(m => m.Members)
                .FirstOrDefaultAsync(m => m.Id == id);
        }

        public async Task<Meeting?> GetByPublicIdAsync(string publicId)
        {
            if (string.IsNullOrWhiteSpace(publicId))
                return null;

            return await _context.Meetings
                .AsNoTracking()
                .FirstOrDefaultAsync(m => m.PublicId == publicId.Trim());
        }

        public async Task<int?> GetMeetingIdByPublicIdAsync(string publicId)
        {
            var meeting = await GetByPublicIdAsync(publicId);
            return meeting?.Id;
        }

        public async Task<Meeting?> GetByNameAsync(string name)
        {
            return await _context.Meetings
                .Include(m => m.Servants)
                .Include(m => m.Members)
                .FirstOrDefaultAsync(m => m.Name == name);
        }

        public async Task AddAsync(Meeting meeting)
        {
            await _context.Meetings.AddAsync(meeting);
            await _context.SaveChangesAsync();
        }

        public async Task<List<Meeting>> GetByChurchIdAsync(int churchid)
        {
            return await _context.Meetings
                .Where(c => c.ChurchId == churchid)
                .ToListAsync();
        }

        public async Task UpdateAsync(Meeting meeting)
        {
            _context.Meetings.Update(meeting);
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
                var classroomIds = await _context.Classrooms
                    .IgnoreQueryFilters()
                    .Where(c => c.MeetingId == id)
                    .Select(c => c.Id)
                    .ToListAsync();

                foreach (var classroomId in classroomIds)
                    await _classroomRepository.DeleteWithDependenciesCoreAsync(classroomId);

                await _memberRepository.DeleteByMeetingIdAsync(id);

                await _context.ExamResults
                    .IgnoreQueryFilters()
                    .Where(er => er.MeetingId == id)
                    .ExecuteDeleteAsync();

                await _context.Exams
                    .IgnoreQueryFilters()
                    .Where(e => e.MeetingId == id)
                    .ExecuteDeleteAsync();

                await _context.Tools
                    .IgnoreQueryFilters()
                    .Where(t => t.MeetingId == id)
                    .ExecuteDeleteAsync();

                await _context.SpiritualCurriculums
                    .IgnoreQueryFilters()
                    .Where(s => s.MeetingId == id)
                    .ExecuteDeleteAsync();

                await _context.ClassroomServants
                    .IgnoreQueryFilters()
                    .Where(cs => cs.MeetingId == id)
                    .ExecuteDeleteAsync();

                await _context.Servants
                    .IgnoreQueryFilters()
                    .Where(s => s.MeetingId == id)
                    .ExecuteUpdateAsync(s => s.SetProperty(x => x.MeetingId, (int?)null));

                await _context.Users
                    .IgnoreQueryFilters()
                    .Where(u => u.MeetingId == id)
                    .ExecuteUpdateAsync(s => s.SetProperty(u => u.MeetingId, (int?)null));

                await _context.CustomFieldValues
                    .IgnoreQueryFilters()
                    .Where(v =>
                        v.EntityName == CustomFieldEntityNames.Meeting &&
                        v.EntityId == id)
                    .ExecuteDeleteAsync();

                await _context.Meetings
                    .IgnoreQueryFilters()
                    .Where(m => m.Id == id)
                    .ExecuteUpdateAsync(s => s.SetProperty(m => m.LeaderServantId, (int?)null));

                var meeting = await _context.Meetings
                    .IgnoreQueryFilters()
                    .FirstOrDefaultAsync(m => m.Id == id);

                if (meeting == null)
                {
                    await transaction.CommitAsync();
                    return;
                }

                _context.Meetings.Remove(meeting);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
    }
}
