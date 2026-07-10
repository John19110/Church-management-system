using Microsoft.EntityFrameworkCore;
using Church.DAL.Models.CustomFields;
using Church.DAL.Repository.Interfaces;
using Church.Domain;
using Church.DAL.DBcontext;

namespace Church.DAL.Repository.Implementations
{
    public class CustomFieldRepository : ICustomFieldRepository
    {
        private readonly ProgramContext _context;

        public CustomFieldRepository(ProgramContext context)
        {
            _context = context;
        }

        public async Task<IReadOnlyList<CustomFieldDefinition>> GetDefinitionsByEntityAsync(
            string entityName, bool includeInactive = false, bool includePermanentlyDeleted = false)
        {
            var query = _context.CustomFieldDefinitions
                .AsNoTracking()
                .Where(d => d.EntityName == entityName);

            if (!includePermanentlyDeleted)
                query = query.Where(d => !d.IsPermanentlyDeleted);

            if (!includeInactive)
                query = query.Where(d => d.IsActive);

            var definitions = await query
                .OrderBy(d => d.SortOrder)
                .ThenBy(d => d.DisplayName)
                .ToListAsync();

            if (definitions.Count == 0)
                return definitions;

            await AttachOptionsAsync(definitions);
            return definitions;
        }

        public async Task<HashSet<string>> GetDefinitionNamesByEntityAsync(string entityName)
        {
            var names = await _context.CustomFieldDefinitions
                .AsNoTracking()
                .Where(d => d.EntityName == entityName)
                .Select(d => d.Name)
                .ToListAsync();

            return names.ToHashSet(StringComparer.OrdinalIgnoreCase);
        }

        public async Task<HashSet<string>> GetPermanentlyDeletedDefinitionNamesByEntityAsync(
            string entityName)
        {
            var names = await _context.CustomFieldDefinitions
                .AsNoTracking()
                .Where(d => d.EntityName == entityName && d.IsPermanentlyDeleted)
                .Select(d => d.Name)
                .ToListAsync();

            return names.ToHashSet(StringComparer.OrdinalIgnoreCase);
        }

        public async Task<CustomFieldDefinition?> GetDefinitionByIdAsync(int id, bool includeOptions = true)
        {
            var definition = await _context.CustomFieldDefinitions
                .AsNoTracking()
                .FirstOrDefaultAsync(d => d.Id == id && !d.IsPermanentlyDeleted);

            if (definition == null || !includeOptions)
                return definition;

            await AttachOptionsAsync(new[] { definition });
            return definition;
        }

        public async Task<CustomFieldDefinition?> GetTrackedDefinitionByIdAsync(
            int id, bool includeOptions = true)
        {
            IQueryable<CustomFieldDefinition> query = _context.CustomFieldDefinitions;
            if (includeOptions)
                query = query.Include(d => d.Options);

            return await query.FirstOrDefaultAsync(d => d.Id == id && !d.IsPermanentlyDeleted);
        }

        public async Task<CustomFieldDefinition?> GetDefinitionByNameAsync(string entityName, string name)
        {
            var definition = await _context.CustomFieldDefinitions
                .AsNoTracking()
                .FirstOrDefaultAsync(d =>
                    d.EntityName == entityName
                    && d.Name == name
                    && !d.IsPermanentlyDeleted);

            if (definition == null)
                return null;

            await AttachOptionsAsync(new[] { definition });
            return definition;
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

        public Task SaveChangesAsync(CancellationToken cancellationToken = default) =>
            _context.SaveChangesAsync(cancellationToken);

        public async Task<IReadOnlyList<CustomFieldDefinition>> GetTrackedDefinitionsByEntityAsync(
            string entityName, bool includeInactive = false)
        {
            var query = _context.CustomFieldDefinitions
                .Where(d => d.EntityName == entityName && !d.IsPermanentlyDeleted);

            if (!includeInactive)
                query = query.Where(d => d.IsActive);

            return await query
                .OrderBy(d => d.SortOrder)
                .ThenBy(d => d.DisplayName)
                .ToListAsync();
        }

        public async Task DeleteDefinitionAsync(int id)
        {
            await RemoveValuesForDefinitionAsync(id);

            var definition = await _context.CustomFieldDefinitions
                .FirstOrDefaultAsync(d => d.Id == id);

            if (definition == null)
                return;

            _context.CustomFieldDefinitions.Remove(definition);
            await _context.SaveChangesAsync();
        }

        public async Task TombstoneDefinitionAsync(int id)
        {
            await RemoveValuesForDefinitionAsync(id);

            var definition = await _context.CustomFieldDefinitions
                .FirstOrDefaultAsync(d => d.Id == id);

            if (definition == null)
                return;

            definition.IsPermanentlyDeleted = true;
            definition.IsActive = false;
            definition.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }

        private async Task RemoveValuesForDefinitionAsync(int definitionId)
        {
            var values = await _context.CustomFieldValues
                .Where(v => v.CustomFieldDefinitionId == definitionId)
                .ToListAsync();

            if (values.Count > 0)
                _context.CustomFieldValues.RemoveRange(values);
        }

        public async Task<IReadOnlyList<CustomFieldValue>> GetValuesAsync(string entityName, int entityId)
        {
            // Do not Include(Definition): global filters on values/options use Definition navigation
            // and can cause translation/runtime failures; values only need definition id + payload.
            return await _context.CustomFieldValues
                .AsNoTracking()
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

        /// <summary>
        /// Loads options in a second query to avoid filtered Include + OrderBy issues on CustomFieldOption.
        /// </summary>
        private async Task AttachOptionsAsync(IReadOnlyList<CustomFieldDefinition>? definitions)
        {
            if (definitions == null || definitions.Count == 0)
                return;

            var ids = definitions
                .Where(d => d != null)
                .Select(d => d.Id)
                .ToList();

            if (ids.Count == 0)
                return;
            var options = await _context.CustomFieldOptions
                .AsNoTracking()
                .Where(o => ids.Contains(o.CustomFieldDefinitionId))
                .OrderBy(o => o.SortOrder)
                .ToListAsync();

            var byDefinition = options
                .GroupBy(o => o.CustomFieldDefinitionId)
                .ToDictionary(g => g.Key, g => g.ToList());

            foreach (var definition in definitions)
            {
                if (definition == null)
                    continue;

                definition.Options ??= new List<CustomFieldOption>();
                definition.Options.Clear();
                if (byDefinition.TryGetValue(definition.Id, out var list))
                {
                    foreach (var option in list)
                        definition.Options.Add(option);
                }
            }
        }
    }
}
