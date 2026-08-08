using Microsoft.EntityFrameworkCore;
using Church.DAL.Models;
using Church.DAL.Repository.Interfaces;
using Church.Domain;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Church.DAL.DBcontext;

namespace Church.DAL.Repository.Implementations
{
    public class ChurchRepository: IChurchRepository
    {
        private readonly ProgramContext _context;
        public ChurchRepository(ProgramContext context)
        {
            _context = context;

        }

        public async Task AddAsync(ChurchModel church)
        {
 
            await _context.Churches.AddAsync(church);
            await _context.SaveChangesAsync();
        }

        /// <summary>Tenant-scoped: only resolves the caller's own church.</summary>
        public async Task<ChurchModel?> GetByIdAsync(int id)
        {
            return await _context.Churches
                .Include(c => c.Members)
                .Include(c => c.Servants)
                .Include(c => c.Meetings)
                .FirstOrDefaultAsync(c => c.Id == id);
        }

        /// <summary>
        /// Resolves a church by internal id without tenant scoping. Only for anonymous
        /// self-registration, where the church is identified by its public join code and no
        /// tenant exists yet. Never call this from a request that already has a tenant.
        /// </summary>
        public async Task<ChurchModel?> GetByIdUnscopedAsync(int id)
        {
            return await _context.Churches
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(c => c.Id == id);
        }

        /// <remarks>The public id is the church join code and is intentionally resolvable anonymously.</remarks>
        public async Task<ChurchModel?> GetByPublicIdAsync(string publicId)
        {
            if (string.IsNullOrWhiteSpace(publicId))
                return null;

            return await _context.Churches
                .AsNoTracking()
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(c => c.PublicId == publicId.Trim()
                    || c.PublicId == publicId.Trim().ToUpperInvariant());
        }

        public async Task<int?> GetChurchIdByPublicIdAsync(string publicId)
        {
            var church = await GetByPublicIdAsync(publicId);
            return church?.Id;
        }

        public async Task<bool> ExistsPublicIdAsync(string publicId, int? excludeChurchId = null)
        {
            if (string.IsNullOrWhiteSpace(publicId))
                return false;

            var normalized = publicId.Trim().ToUpperInvariant();
            // Uniqueness of a join code is global, so this must see every church.
            var query = _context.Churches.AsNoTracking()
                .IgnoreQueryFilters()
                .Where(c => c.PublicId == normalized || c.PublicId == publicId.Trim());

            if (excludeChurchId.HasValue)
                query = query.Where(c => c.Id != excludeChurchId.Value);

            return await query.AnyAsync();
        }

        /// <remarks>Startup schema repair; runs with no tenant.</remarks>
        public async Task<List<ChurchModel>> GetChurchesNeedingShortPublicIdAsync()
        {
            return await _context.Churches
                .IgnoreQueryFilters()
                .Where(c => c.PublicId == null
                    || c.PublicId == string.Empty
                    || c.PublicId.Length > 10)
                .ToListAsync();
        }

        /// <remarks>Used by anonymous registration to detect duplicate church names.</remarks>
        public async Task<ChurchModel?> GetByNameAsync(string churchName)
        {
            return await _context.Churches
                .AsNoTracking()
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(c => c.Name == churchName);
        }

        public async Task UpdateAsync(ChurchModel church)
        {
            _context.Churches.Update(church);
            await _context.SaveChangesAsync();
        }



    }
}
