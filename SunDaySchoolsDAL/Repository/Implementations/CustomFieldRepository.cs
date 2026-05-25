using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Models.CustomFields;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;

namespace SunDaySchools.DAL.Repository.Implementations
{
    public class CustomFieldRepository : ICustomFieldRepository
    {
        private readonly ProgramContext _context;

        public CustomFieldRepository(ProgramContext context)
        {
            _context = context;
        }

        public async Task<IReadOnlyList<CustomFieldDefinition>> GetDefinitionsByEntityAsync(
            string entityName, bool includeInactive = false)
        {
            var query = _context.CustomFieldDefinitions
                .AsNoTracking()
                .Include(d => d.Options.OrderBy(o => o.SortOrder))
                .Where(d => d.EntityName == entityName);

            if (!includeInactive)
                query = query.Where(d => d.IsActive);

            return await query
                .OrderBy(d => d.SortOrder)
                .ThenBy(d => d.DisplayName)
                .ToListAsync();
        }

        public async Task<CustomFieldDefinition?> GetDefinitionByIdAsync(int id, bool includeOptions = true)
        {
            IQueryable<CustomFieldDefinition> query = _context.CustomFieldDefinitions;

            if (includeOptions)
                query = query.Include(d => d.Options.OrderBy(o => o.SortOrder));

            return await query.FirstOrDefaultAsync(d => d.Id == id);
        }

        public async Task<CustomFieldDefinition?> GetDefinitionByNameAsync(string entityName, string name)
        {
            return await _context.CustomFieldDefinitions
                .Include(d => d.Options)
                .FirstOrDefaultAsync(d => d.EntityName == entityName && d.Name == name);
        }

        public async Task AddDefinitionAsync(CustomFieldDefinition definition)
        {
            await _context.CustomFieldDefinitions.AddAsync(definition);
            await _context.SaveChangesAsync();
        }

        public async Task UpdateDefinitionAsync(CustomFieldDefinition definition)
        {
            await _context.SaveChangesAsync();
        }

        public async Task<IReadOnlyList<CustomFieldValue>> GetValuesAsync(string entityName, int entityId)
        {
            return await _context.CustomFieldValues
                .AsNoTracking()
                .Include(v => v.Definition)
                .Where(v => v.EntityName == entityName && v.EntityId == entityId)
                .ToListAsync();
        }

        public async Task<CustomFieldValue?> GetValueAsync(int definitionId, string entityName, int entityId)
        {
            return await _context.CustomFieldValues
                .FirstOrDefaultAsync(v =>
                    v.CustomFieldDefinitionId == definitionId &&
                    v.EntityName == entityName &&
                    v.EntityId == entityId);
        }

        public async Task UpsertValuesAsync(IEnumerable<CustomFieldValue> values)
        {
            foreach (var value in values)
            {
                var existing = await _context.CustomFieldValues
                    .FirstOrDefaultAsync(v =>
                        v.CustomFieldDefinitionId == value.CustomFieldDefinitionId &&
                        v.EntityName == value.EntityName &&
                        v.EntityId == value.EntityId);

                if (existing == null)
                {
                    await _context.CustomFieldValues.AddAsync(value);
                }
                else
                {
                    existing.Value = value.Value;
                    existing.UpdatedAt = value.UpdatedAt ?? DateTime.UtcNow;
                }
            }

            await _context.SaveChangesAsync();
        }

        public async Task<int> CountValuesForDefinitionAsync(int definitionId)
        {
            return await _context.CustomFieldValues
                .CountAsync(v => v.CustomFieldDefinitionId == definitionId && v.Value != null && v.Value != "");
        }

        public async Task<IReadOnlyList<string>> GetDistinctRawValuesAsync(int definitionId, int maxSample = 500)
        {
            return await _context.CustomFieldValues
                .AsNoTracking()
                .Where(v => v.CustomFieldDefinitionId == definitionId && v.Value != null && v.Value != "")
                .Select(v => v.Value!)
                .Distinct()
                .Take(maxSample)
                .ToListAsync();
        }

        public async Task<bool> EntityExistsAsync(string entityName, int entityId)
        {
            return entityName switch
            {
                CustomFieldEntityNames.Member => await _context.Members.AnyAsync(m => m.Id == entityId),
                CustomFieldEntityNames.Classroom => await _context.Classrooms.AnyAsync(c => c.Id == entityId),
                CustomFieldEntityNames.Servant => await _context.Servants.AnyAsync(s => s.Id == entityId),
                CustomFieldEntityNames.Meeting => await _context.Meetings.AnyAsync(m => m.Id == entityId),
                _ => false
            };
        }
    }
}
