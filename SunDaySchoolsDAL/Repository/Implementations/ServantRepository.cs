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

        public async Task AddAsync(Servant servant)
        {
            await _context.Servants.AddAsync(servant);
            await _context.SaveChangesAsync();
        }
        public async Task<IEnumerable<Servant>> GetAllAsync()
        {// edit here 
            return await _context.Servants
                .Include(s=> s.ClassroomServants)
                .ThenInclude(cs => cs.Classroom)
                .Include(s => s.ApplicationUser)
                .ToListAsync();
        }

        public async Task<Servant?> GetByIdAsync(int id)
        {
            if (id <= 0)
                return null;

            // Include classrooms via join entity — do not ThenInclude Servant (same root type),
            // or EF throws NavigationBaseIncludeIgnored / invalid include graph.
            return await _context.Servants
                .Include(s => s.ClassroomServants)
                .ThenInclude(cs => cs.Classroom)
                .Include(s => s.ApplicationUser)
                .FirstOrDefaultAsync(s => s.Id == id);
        }

        public async Task<List<Servant>> GetByIdsAsync(List<int> ids)
        {
            return await _context.Servants
                .Where(s => ids.Contains(s.Id))
                .ToListAsync();
        }



        public async Task<IEnumerable<Classroom>> GetByServantIdAsync(int servantId)
        {
            return await _context.Set<ClassroomServant>()
                .Where(cs => cs.ServantId == servantId)
                .Select(cs => cs.Classroom)
                .ToListAsync();
        }
        /// <summary>
        /// Resolves the servant row for an ASP.NET Identity user id (<see cref="Servant.ApplicationUserId"/>).
        /// No Include graph: loading <c>Servant → ApplicationUser</c> from <c>Users</c> caused EF Core
        /// <c>NavigationBaseIncludeIgnored</c> on the one-to-one inverse. Callers only need the servant entity key and scalars.
        /// </summary>
        public async Task<Servant?> GetByApplicationUserIdAsync(string applicationUserId)
        {
            if (string.IsNullOrWhiteSpace(applicationUserId))
                return null;

            return await _context.Servants
                .AsNoTracking()
                .FirstOrDefaultAsync(s => s.ApplicationUserId == applicationUserId);
        }

        public async Task UpdateAsync(Servant servant)
        {
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(int id)
        {
            if (id <= 0)
                return;

            var servant = await _context.Servants.FindAsync(id);

            if (servant != null)
            {
                _context.Servants.Remove(servant);
                await _context.SaveChangesAsync();
            }
        }
    }
}