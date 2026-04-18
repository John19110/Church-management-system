using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;
using SunDaySchoolsDAL.Models;
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

        public async Task<List<int>> GetClassroomIdsByApplicationUserIdAsync(string applicationUserId)
        {
            if (string.IsNullOrWhiteSpace(applicationUserId))
                return new List<int>();

            var servantId = await _context.Servants
                .IgnoreQueryFilters()
                .Where(s => s.ApplicationUserId == applicationUserId)
                .Select(s => (int?)s.Id)
                .FirstOrDefaultAsync();

            if (!servantId.HasValue)
                return new List<int>();

            return await _context.Set<ClassroomServant>()
                .IgnoreQueryFilters()
                .Where(cs => cs.ServantId == servantId.Value)
                .Select(cs => cs.ClassroomId)
                .Distinct()
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
                .FirstOrDefaultAsync(s => s.ApplicationUserId == applicationUserId);
        }

        public async Task<Servant?> EnsureServantProfileAsync(ApplicationUser user, bool autoCreateMissing)
        {
            if (user == null)
                return null;

            var existing = await GetByApplicationUserIdAsync(user.Id);
            if (existing != null)
                return existing;

            if (!autoCreateMissing)
                return null;

            var servant = new Servant
            {
                ApplicationUserId = user.Id,
                Name = user.UserName,
                PhoneNumber = user.PhoneNumber,
                ChurchId = user.ChurchId,
                MeetingId = user.MeetingId
            };

            await _context.Servants.AddAsync(servant);
            await _context.SaveChangesAsync();
            return servant;
        }

        public async Task<bool> HasServantProfileLinkedAsync(string applicationUserId)
        {
            if (string.IsNullOrWhiteSpace(applicationUserId))
                return false;

            return await _context.Servants
                .IgnoreQueryFilters()
                .AnyAsync(s => s.ApplicationUserId == applicationUserId);
        }

        public async Task UpdateAsync(Servant servant)
        {
            await _context.SaveChangesAsync();
        }

        public async Task<bool> DeleteAsync(int id)
        {
            if (id <= 0)
                return false;

            var servant = await _context.Servants.FindAsync(id);
            if (servant == null)
                return false;

            _context.Servants.Remove(servant);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}