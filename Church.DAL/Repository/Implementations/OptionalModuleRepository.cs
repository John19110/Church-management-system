using Church.DAL.DBcontext;
using Church.DAL.Models.OptionalModules;
using Church.DAL.Repository.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Church.DAL.Repository.Implementations
{
    public class OptionalModuleRepository : IOptionalModuleRepository
    {
        private readonly ProgramContext _context;

        public OptionalModuleRepository(ProgramContext context)
        {
            _context = context;
        }

        public async Task<IReadOnlyList<OrganizationModuleActivation>> GetActivationsAsync()
        {
            return await _context.OrganizationModuleActivations
                .AsNoTracking()
                .ToListAsync();
        }

        public async Task<OrganizationModuleActivation?> GetActivationForScopeAsync(
            string moduleId,
            int? meetingId)
        {
            return await _context.OrganizationModuleActivations
                .FirstOrDefaultAsync(a =>
                    a.ModuleId == moduleId &&
                    a.MeetingId == meetingId);
        }

        public async Task AddActivationAsync(OrganizationModuleActivation activation)
        {
            await _context.OrganizationModuleActivations.AddAsync(activation);
        }

        public async Task UpdateActivationAsync(OrganizationModuleActivation activation)
        {
            var entry = _context.Entry(activation);
            if (entry.State == EntityState.Detached)
                _context.OrganizationModuleActivations.Update(activation);
        }

        public async Task SaveChangesAsync()
        {
            await _context.SaveChangesAsync();
        }
    }
}
