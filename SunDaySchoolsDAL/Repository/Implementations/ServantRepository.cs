using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Repository.Implementations
{
    public class ServantRepository : IServantRepository
    {
        private readonly ProgramContext _context;

        public ServantRepository(ProgramContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Servant>> GetAllAsync()
        {
            return await _context.Servants
                .Include(s => s.Classrooms)
                .Include(s => s.ApplicationUser)
                .ToListAsync();
        }

        public async Task<Servant?> GetByIdAsync(int id)
        {
            return await _context.Servants
                .Include(s => s.Classrooms)
                .Include(s => s.ApplicationUser)
                .FirstOrDefaultAsync(s => s.Id == id);
        }

        public async Task<IEnumerable<Classroom>> GetByServantIdAsync(int servantId)
        {
            return await _context.Classrooms
                .Where(c => c.Servants.Any(s => s.Id == servantId))
                .ToListAsync();
        }

        public async Task<Servant?> GetByApplicationUserIdAsync(string applicationUserId)
        {
            return await _context.Servants
                .Include(s => s.Classrooms)
                .Include(s => s.ApplicationUser)
                .FirstOrDefaultAsync(s => s.ApplicationUserId == applicationUserId);
        }

        public async Task UpdateAsync(Servant servant)
        {
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(int id)
        {
            var servant = await _context.Servants.FindAsync(id);

            if (servant != null)
            {
                _context.Servants.Remove(servant);
                await _context.SaveChangesAsync();
            }
        }
    }
}