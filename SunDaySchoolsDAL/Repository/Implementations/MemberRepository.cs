using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Models.CustomFields;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Repository.Implementations
{
    public class MemberRepository : IMemberRepository
    {
        private readonly ProgramContext _context;

        public MemberRepository(ProgramContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Member>> GetAllAsync()
        {
            return await _context.Members
                .Include(c => c.PhoneNumbers)
                .ToListAsync();
        }
        public async Task<List<(int Id, string Name)>> GetMembersForSelection()
        {
            return await _context.Members
                .AsNoTracking()
                .Select(m => new ValueTuple<int, string>(m.Id, m.FullName))
                .ToListAsync();
        }
        public async Task<Member?> GetByIdAsync(int id)
        {
            if (id <= 0)
                return null;

            return await _context.Members
                .Include(c => c.PhoneNumbers)
                .FirstOrDefaultAsync(c => c.Id == id);
        }

        public async Task<Member?> GetByIdForFormAsync(int id)
        {
            if (id <= 0)
                return null;

            return await _context.Members
                .AsNoTracking()
                .FirstOrDefaultAsync(c => c.Id == id);
        }

        public async Task<IReadOnlyList<(string? Relation, string? PhoneNumber)>> GetContactPhonesForFormAsync(
            int memberId)
        {
            if (memberId <= 0)
                return Array.Empty<(string?, string?)>();

            return await _context.MemberContacts
                .AsNoTracking()
                .Where(mc => mc.MemberId == memberId)
                .Select(mc => new ValueTuple<string?, string?>(mc.Relation, mc.PhoneNumber))
                .ToListAsync();
        }

        public async Task<List<Member>> GetByIdsAsync(List<int> ids)
        {
            return await _context.Members
                .Where(m => ids.Contains(m.Id))
                .ToListAsync();
        }



        public async Task AddAsync(Member member)
        {
            await _context.Members.AddAsync(member);
            await _context.SaveChangesAsync();
        }

        public async Task UpdateAsync(Member member)
        {
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(int id)
        {
            if (id <= 0)
                return;

            await DeleteWithDependenciesAsync(id);
            await _context.SaveChangesAsync();
        }

        public async Task DeleteWithDependenciesAsync(int memberId)
        {
            if (memberId <= 0)
                return;

            await _context.ExamResults
                .IgnoreQueryFilters()
                .Where(er => er.MemberId == memberId)
                .ExecuteDeleteAsync();

            await _context.AttendanceRecords
                .IgnoreQueryFilters()
                .Where(r => r.MemberId == memberId)
                .ExecuteDeleteAsync();

            await _context.CustomFieldValues
                .IgnoreQueryFilters()
                .Where(v =>
                    v.EntityName == CustomFieldEntityNames.Member &&
                    v.EntityId == memberId)
                .ExecuteDeleteAsync();

            var member = await _context.Members
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(m => m.Id == memberId);

            if (member == null)
                return;

            _context.Members.Remove(member);
        }

        public async Task DeleteByClassroomIdAsync(int classroomId)
        {
            if (classroomId <= 0)
                return;

            var memberIds = await _context.Members
                .IgnoreQueryFilters()
                .Where(m => m.ClassroomId == classroomId)
                .Select(m => m.Id)
                .ToListAsync();

            foreach (var memberId in memberIds)
                await DeleteWithDependenciesAsync(memberId);
        }

        public async Task DeleteByMeetingIdAsync(int meetingId)
        {
            if (meetingId <= 0)
                return;

            var memberIds = await _context.Members
                .IgnoreQueryFilters()
                .Where(m => m.MeetingId == meetingId)
                .Select(m => m.Id)
                .ToListAsync();

            foreach (var memberId in memberIds)
                await DeleteWithDependenciesAsync(memberId);
        }

        public async Task<IEnumerable<Member>> GetSpecificClassroomAsync(int classroomId)
        {
            return await _context.Members
                .AsNoTracking()
                .Include(m => m.PhoneNumbers)
                .Where(m => m.ClassroomId == classroomId)
                .ToListAsync();
        }

        public async Task SaveAsync()
        {
            await _context.SaveChangesAsync();
        }

    }
}