using Microsoft.EntityFrameworkCore;
using Church.DAL.Repository.Interfaces;
using Church.Domain;
using Church.DAL.DBcontext;
using Church.DAL.Models;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Church.DAL.Repository.Implementations
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
        {
            // Only approved accounts are real servants. Pending/Rejected registrations must
            // never appear here even if a Servant row exists (legacy data / re-runs).
            return await _context.Servants
                .Include(s=> s.ClassroomServants)
                .ThenInclude(cs => cs.Classroom)
                .Include(s => s.ApplicationUser)
                .Where(s => s.ApplicationUser != null
                            && s.ApplicationUser.RegistrationStatus == RegistrationStatus.Approved)
                .ToListAsync();
        }

        public async Task<List<(int Id, string Name)>> GetServantsForSelection()
        {
            return await _context.Servants
                .AsNoTracking()
                .Select(s => new ValueTuple<int, string>(s.Id, s.Name))
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

        public async Task<IEnumerable<Servant>> GetByMeetingIdAsync(int meetingId)
        {
            return await _context.Servants
                .Include(s => s.ClassroomServants)
                .ThenInclude(cs => cs.Classroom)
                .Include(s => s.ApplicationUser)
                .Where(s => s.MeetingId == meetingId
                            && s.ApplicationUser != null
                            && s.ApplicationUser.RegistrationStatus == RegistrationStatus.Approved)
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

        public Task<Servant?> GetProfileByApplicationUserIdAsync(
            string applicationUserId,
            CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(applicationUserId))
                return Task.FromResult<Servant?>(null);

            return _context.Servants
                .AsNoTracking()
                .Include(s => s.ApplicationUser)
                .Include(s => s.Church)
                .Include(s => s.Meeting)
                .Include(s => s.ClassroomServants)
                    .ThenInclude(cs => cs.Classroom)
                .FirstOrDefaultAsync(s => s.ApplicationUserId == applicationUserId, cancellationToken);
        }

        public Task<Servant?> GetTrackedProfileByApplicationUserIdAsync(
            string applicationUserId,
            CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(applicationUserId))
                return Task.FromResult<Servant?>(null);

            return _context.Servants
                .Include(s => s.ApplicationUser)
                .Include(s => s.ClassroomServants)
                .FirstOrDefaultAsync(s => s.ApplicationUserId == applicationUserId, cancellationToken);
        }

        public Task SaveChangesAsync(CancellationToken cancellationToken = default) =>
            _context.SaveChangesAsync(cancellationToken);

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

        public async Task<ServantDeleteOutcome> DeleteAsync(int id)
        {
            if (id <= 0)
                return new ServantDeleteOutcome();

            await using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var servant = await _context.Servants
                    .IgnoreQueryFilters()
                    .FirstOrDefaultAsync(s => s.Id == id);

                if (servant == null)
                {
                    await transaction.RollbackAsync();
                    return new ServantDeleteOutcome();
                }

                var applicationUserId = servant.ApplicationUserId;

                await _context.AttendanceSessions
                    .IgnoreQueryFilters()
                    .Where(s => s.TakenByServantId == id)
                    .ExecuteUpdateAsync(s => s.SetProperty(x => x.TakenByServantId, (int?)null));

                await _context.Meetings
                    .IgnoreQueryFilters()
                    .Where(m => m.LeaderServantId == id)
                    .ExecuteUpdateAsync(s => s.SetProperty(x => x.LeaderServantId, (int?)null));

                await _context.Classrooms
                    .IgnoreQueryFilters()
                    .Where(c => c.LeaderServantId == id)
                    .ExecuteUpdateAsync(s => s.SetProperty(x => x.LeaderServantId, (int?)null));

                await _context.Churches
                    .Where(ch => ch.PastorId == id)
                    .ExecuteUpdateAsync(s => s.SetProperty(x => x.PastorId, (int?)null));

                await _context.Database.ExecuteSqlInterpolatedAsync(
                    $"UPDATE PhoneCalls SET ServantId = NULL WHERE ServantId = {id}");

                await _context.ClassroomServants
                    .IgnoreQueryFilters()
                    .Where(cs => cs.ServantId == id)
                    .ExecuteDeleteAsync();

                var servantRole = await _context.Roles
                    .FirstOrDefaultAsync(r => r.Name == "Servant");

                if (servantRole != null)
                {
                    await _context.UserRoles
                        .Where(ur => ur.UserId == applicationUserId && ur.RoleId == servantRole.Id)
                        .ExecuteDeleteAsync();
                }

                _context.Servants.Remove(servant);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return new ServantDeleteOutcome
                {
                    Deleted = true,
                    ApplicationUserId = applicationUserId
                };
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
    }
}