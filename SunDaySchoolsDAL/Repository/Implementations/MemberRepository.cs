using Microsoft.EntityFrameworkCore;
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

        public async Task<Member?> GetByIdAsync(int id)
        {
            if (id <= 0)
                return null;

            return await _context.Members
                .Include(c => c.PhoneNumbers)
                .FirstOrDefaultAsync(c => c.Id == id);
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

            var member = await _context.Members.FindAsync(id);

            if (member != null)
            {
                _context.Members.Remove(member);
                await _context.SaveChangesAsync();
            }
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