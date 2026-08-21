using Church.DAL.DBcontext;
using Church.DAL.Models;
using Church.DAL.Repository.Interfaces;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Church.DAL.Repository.Implementations
{
    public class AttendanceCriterionRepository : IAttendanceCriterionRepository
    {
        public const string HasToolsName = AttendanceCriterionNames.HasTools;
        public const string DidHomeworkName = AttendanceCriterionNames.DidHomework;

        private readonly ProgramContext _context;

        public AttendanceCriterionRepository(ProgramContext context)
        {
            _context = context;
        }

        public async Task<List<AttendanceCriterion>> GetByMeetingAsync(int meetingId, bool includeDeleted = false)
        {
            var query = _context.AttendanceCriteria
                .AsNoTracking()
                .Where(c => c.MeetingId == meetingId);

            if (!includeDeleted)
                query = query.Where(c => !c.IsDeleted);

            return await query
                .OrderBy(c => c.SortOrder)
                .ThenBy(c => c.Id)
                .ToListAsync();
        }

        public async Task<AttendanceCriterion?> GetByIdAsync(int id)
        {
            return await _context.AttendanceCriteria.FirstOrDefaultAsync(c => c.Id == id);
        }

        public async Task<AttendanceCriterion> AddAsync(AttendanceCriterion criterion)
        {
            await _context.AttendanceCriteria.AddAsync(criterion);
            await _context.SaveChangesAsync();
            return criterion;
        }

        public async Task UpdateAsync(AttendanceCriterion criterion)
        {
            _context.AttendanceCriteria.Update(criterion);
            await _context.SaveChangesAsync();
        }

        public async Task EnsureDefaultsForMeetingAsync(int meetingId, int churchId)
        {
            // Seed only when the meeting has never had any criteria (including soft-deleted).
            // Otherwise soft-deleting has_tools / did_homework would look like a missing default
            // and recreate them on every GET.
            var anyExist = await _context.AttendanceCriteria
                .AnyAsync(c => c.MeetingId == meetingId);
            if (anyExist) return;

            var toAdd = new List<AttendanceCriterion>
            {
                new AttendanceCriterion
                {
                    Name = HasToolsName,
                    DisplayName = "Has own tools",
                    DisplayNameAr = "يملك الأدوات",
                    DataType = AttendanceCriterionDataType.Boolean,
                    IsActive = true,
                    SortOrder = 0,
                    MeetingId = meetingId,
                    ChurchId = churchId,
                    CreatedAt = DateTime.UtcNow
                },
                new AttendanceCriterion
                {
                    Name = DidHomeworkName,
                    DisplayName = "Did homework",
                    DisplayNameAr = "أدى الواجب",
                    DataType = AttendanceCriterionDataType.Boolean,
                    IsActive = true,
                    SortOrder = 1,
                    MeetingId = meetingId,
                    ChurchId = churchId,
                    CreatedAt = DateTime.UtcNow
                }
            };

            await _context.AttendanceCriteria.AddRangeAsync(toAdd);
            await _context.SaveChangesAsync();
        }
    }
}
