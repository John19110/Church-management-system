using System.Text.Json;
using Church.DAL.DBcontext;
using Church.DAL.Models.CustomFeatures;
using Church.DAL.Repository.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Church.DAL.Repository.Implementations
{
    public class CustomFeatureRepository : ICustomFeatureRepository
    {
        private readonly ProgramContext _context;

        public CustomFeatureRepository(ProgramContext context)
        {
            _context = context;
        }

        public async Task<IReadOnlyList<CustomFeature>> GetFeaturesAsync(bool includeInactive = false)
        {
            var query = _context.CustomFeatures
                .AsNoTracking()
                .Include(f => f.Entities.Where(e => includeInactive || e.IsActive))
                .AsQueryable();

            if (!includeInactive)
                query = query.Where(f => f.IsActive);

            return await query
                .OrderBy(f => f.DisplayName)
                .ToListAsync();
        }

        public async Task<CustomFeature?> GetFeatureByIdAsync(int id, bool includeEntities = true)
        {
            var query = _context.CustomFeatures.AsQueryable();
            if (includeEntities)
            {
                query = query
                    .Include(f => f.Entities)
                    .ThenInclude(e => e.Fields)
                    .ThenInclude(field => field.Options)
                    .Include(f => f.Entities)
                    .ThenInclude(e => e.Permissions);
            }

            return await query.FirstOrDefaultAsync(f => f.Id == id);
        }

        public Task<CustomFeature?> GetFeatureByNameAsync(string name) =>
            _context.CustomFeatures.FirstOrDefaultAsync(f => f.Name == name);

        public Task<int> CountFeaturesAsync() =>
            _context.CustomFeatures.CountAsync();

        public async Task AddFeatureAsync(CustomFeature feature)
        {
            await _context.CustomFeatures.AddAsync(feature);
        }

        public async Task DeleteFeatureAsync(CustomFeature feature)
        {
            var entityIds = await _context.CustomEntities
                .Where(e => e.FeatureId == feature.Id)
                .Select(e => e.Id)
                .ToListAsync();

            var recordIds = await _context.CustomEntityRecords
                .Where(r => entityIds.Contains(r.EntityId))
                .Select(r => r.Id)
                .ToListAsync();

            var fieldIds = await _context.CustomEntityFields
                .Where(f => entityIds.Contains(f.EntityId))
                .Select(f => f.Id)
                .ToListAsync();

            await RemoveReferencesAsync(recordIds, fieldIds);
            _context.CustomFeatures.Remove(feature);
        }

        public async Task<IReadOnlyList<CustomEntity>> GetEntitiesByFeatureAsync(
            int featureId,
            bool includeInactive = false)
        {
            var query = _context.CustomEntities
                .AsNoTracking()
                .Include(e => e.Fields)
                .ThenInclude(f => f.Options)
                .Include(e => e.Permissions)
                .Where(e => e.FeatureId == featureId);

            if (!includeInactive)
                query = query.Where(e => e.IsActive);

            return await query
                .OrderBy(e => e.SortOrder)
                .ThenBy(e => e.DisplayName)
                .ToListAsync();
        }

        public async Task<CustomEntity?> GetEntityByIdAsync(
            int id,
            bool includeFields = true,
            bool includePermissions = true)
        {
            var query = _context.CustomEntities
                .Include(e => e.Feature)
                .AsQueryable();

            if (includeFields)
                query = query.Include(e => e.Fields).ThenInclude(f => f.Options);

            if (includePermissions)
                query = query.Include(e => e.Permissions);

            return await query.FirstOrDefaultAsync(e => e.Id == id);
        }

        public Task<int> CountEntitiesAsync(int featureId) =>
            _context.CustomEntities.CountAsync(e => e.FeatureId == featureId);

        public async Task AddEntityAsync(CustomEntity entity)
        {
            await _context.CustomEntities.AddAsync(entity);
        }

        public async Task DeleteEntityAsync(CustomEntity entity)
        {
            var recordIds = await _context.CustomEntityRecords
                .Where(r => r.EntityId == entity.Id)
                .Select(r => r.Id)
                .ToListAsync();

            var fieldIds = await _context.CustomEntityFields
                .Where(f => f.EntityId == entity.Id)
                .Select(f => f.Id)
                .ToListAsync();

            await RemoveReferencesAsync(recordIds, fieldIds);
            _context.CustomEntities.Remove(entity);
        }

        public async Task<CustomEntityField?> GetFieldByIdAsync(int id, bool includeOptions = true)
        {
            var query = _context.CustomEntityFields
                .Include(f => f.Entity)
                .ThenInclude(e => e!.Feature)
                .AsQueryable();

            if (includeOptions)
                query = query.Include(f => f.Options);

            return await query.FirstOrDefaultAsync(f => f.Id == id);
        }

        public Task<int> CountFieldsAsync(int entityId) =>
            _context.CustomEntityFields.CountAsync(f => f.EntityId == entityId);

        public async Task AddFieldAsync(CustomEntityField field)
        {
            await _context.CustomEntityFields.AddAsync(field);
        }

        public async Task DeleteFieldAsync(CustomEntityField field)
        {
            var refs = await _context.CustomEntityRecordReferences
                .Where(r => r.FieldId == field.Id)
                .ToListAsync();
            _context.CustomEntityRecordReferences.RemoveRange(refs);
            _context.CustomEntityFields.Remove(field);
        }

        public async Task ReplacePermissionsAsync(
            int entityId,
            IReadOnlyList<CustomEntityPermission> permissions)
        {
            var existing = await _context.CustomEntityPermissions
                .Where(p => p.EntityId == entityId)
                .ToListAsync();
            _context.CustomEntityPermissions.RemoveRange(existing);
            await _context.CustomEntityPermissions.AddRangeAsync(permissions);
        }

        public async Task<CustomEntityRecord?> GetRecordByIdAsync(int id, bool includeReferences = true)
        {
            var query = _context.CustomEntityRecords
                .Include(r => r.Entity)
                .ThenInclude(e => e!.Feature)
                .AsQueryable();

            if (includeReferences)
                query = query.Include(r => r.References);

            return await query.FirstOrDefaultAsync(r => r.Id == id);
        }

        public async Task<(IReadOnlyList<CustomEntityRecord> Items, int Total)> GetRecordsAsync(
            int entityId,
            string? search,
            string? sortFieldName,
            bool sortDescending,
            int page,
            int pageSize)
        {
            var query = _context.CustomEntityRecords
                .AsNoTracking()
                .Include(r => r.References)
                .Where(r => r.EntityId == entityId);

            if (!string.IsNullOrWhiteSpace(search))
                query = query.Where(r => r.DataJson.Contains(search));

            var total = await query.CountAsync();
            var sort = (sortFieldName ?? "createdAt").Trim();

            if (IsSqlSort(sort))
            {
                query = ApplySqlSort(query, sort, sortDescending);
                var sqlItems = await query
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .ToListAsync();
                return (sqlItems, total);
            }

            var payloads = await query
                .Select(r => new { r.Id, r.DataJson, r.CreatedAt })
                .ToListAsync();

            IEnumerable<int> orderedIds = sortDescending
                ? payloads.OrderByDescending(p => ReadJsonField(p.DataJson, sort)).ThenByDescending(p => p.Id)
                    .Select(p => p.Id)
                : payloads.OrderBy(p => ReadJsonField(p.DataJson, sort)).ThenBy(p => p.Id)
                    .Select(p => p.Id);

            var pageIds = orderedIds
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToList();

            var items = await _context.CustomEntityRecords
                .AsNoTracking()
                .Include(r => r.References)
                .Where(r => pageIds.Contains(r.Id))
                .ToListAsync();

            var order = pageIds.Select((id, index) => (id, index)).ToDictionary(x => x.id, x => x.index);
            items = items.OrderBy(r => order[r.Id]).ToList();
            return (items, total);
        }

        public async Task AddRecordAsync(CustomEntityRecord record)
        {
            await _context.CustomEntityRecords.AddAsync(record);
        }

        public async Task DeleteRecordAsync(CustomEntityRecord record)
        {
            var incoming = await _context.CustomEntityRecordReferences
                .Where(r => r.TargetRecordId == record.Id)
                .ToListAsync();
            _context.CustomEntityRecordReferences.RemoveRange(incoming);
            _context.CustomEntityRecords.Remove(record);
        }

        public async Task ReplaceRecordReferencesAsync(
            int recordId,
            IReadOnlyList<CustomEntityRecordReference> references)
        {
            var existing = await _context.CustomEntityRecordReferences
                .Where(r => r.RecordId == recordId)
                .ToListAsync();
            _context.CustomEntityRecordReferences.RemoveRange(existing);
            await _context.CustomEntityRecordReferences.AddRangeAsync(references);
        }

        public Task<bool> RecordReferencesTargetAsync(int targetRecordId) =>
            _context.CustomEntityRecordReferences.AnyAsync(r => r.TargetRecordId == targetRecordId);

        public Task<bool> FieldHasReferencesAsync(int fieldId) =>
            _context.CustomEntityRecordReferences.AnyAsync(r => r.FieldId == fieldId);

        public Task<bool> MemberExistsAsync(int memberId) =>
            _context.Members.AnyAsync(m => m.Id == memberId);

        public Task<bool> ServantExistsAsync(int servantId) =>
            _context.Servants.AnyAsync(s => s.Id == servantId);

        public Task<CustomEntityRecord?> GetRecordInEntityAsync(int entityId, int recordId) =>
            _context.CustomEntityRecords
                .AsNoTracking()
                .FirstOrDefaultAsync(r => r.Id == recordId && r.EntityId == entityId);

        public async Task<IReadOnlyList<CustomEntityRecord>> GetRecordsByIdsAsync(
            int entityId,
            IReadOnlyList<int> recordIds)
        {
            if (recordIds.Count == 0)
                return Array.Empty<CustomEntityRecord>();

            return await _context.CustomEntityRecords
                .AsNoTracking()
                .Where(r => r.EntityId == entityId && recordIds.Contains(r.Id))
                .ToListAsync();
        }

        public async Task<IReadOnlyDictionary<int, string?>> GetMemberNamesAsync(IReadOnlyList<int> memberIds)
        {
            if (memberIds.Count == 0)
                return new Dictionary<int, string?>();

            var members = await _context.Members
                .AsNoTracking()
                .Where(m => memberIds.Contains(m.Id))
                .Select(m => new { m.Id, m.Name1, m.Name2, m.Name3 })
                .ToListAsync();

            return members.ToDictionary(
                m => m.Id,
                m => (string?)string.Join(
                    " ",
                    new[] { m.Name1, m.Name2, m.Name3 }.Where(n => !string.IsNullOrWhiteSpace(n))));
        }

        public async Task<IReadOnlyDictionary<int, string?>> GetServantNamesAsync(IReadOnlyList<int> servantIds)
        {
            if (servantIds.Count == 0)
                return new Dictionary<int, string?>();

            return await _context.Servants
                .AsNoTracking()
                .Where(s => servantIds.Contains(s.Id))
                .ToDictionaryAsync(s => s.Id, s => s.Name);
        }

        public async Task<bool> ScalarValueExistsAsync(
            int entityId,
            string fieldName,
            string jsonValue,
            int? excludeRecordId)
        {
            var payloads = await _context.CustomEntityRecords
                .AsNoTracking()
                .Where(r => r.EntityId == entityId && (excludeRecordId == null || r.Id != excludeRecordId))
                .Select(r => r.DataJson)
                .ToListAsync();

            foreach (var json in payloads)
            {
                if (string.Equals(ReadJsonField(json, fieldName), jsonValue, StringComparison.OrdinalIgnoreCase))
                    return true;
            }

            return false;
        }

        public Task SaveChangesAsync(CancellationToken cancellationToken = default) =>
            _context.SaveChangesAsync(cancellationToken);

        private async Task RemoveReferencesAsync(IReadOnlyList<int> recordIds, IReadOnlyList<int> fieldIds)
        {
            if (recordIds.Count == 0 && fieldIds.Count == 0)
                return;

            var refs = await _context.CustomEntityRecordReferences
                .Where(r =>
                    recordIds.Contains(r.RecordId) ||
                    (r.TargetRecordId.HasValue && recordIds.Contains(r.TargetRecordId.Value)) ||
                    fieldIds.Contains(r.FieldId))
                .ToListAsync();
            _context.CustomEntityRecordReferences.RemoveRange(refs);
        }

        private static bool IsSqlSort(string sort) =>
            sort.Equals("createdAt", StringComparison.OrdinalIgnoreCase) ||
            sort.Equals("updatedAt", StringComparison.OrdinalIgnoreCase) ||
            sort.Equals("id", StringComparison.OrdinalIgnoreCase);

        private static IQueryable<CustomEntityRecord> ApplySqlSort(
            IQueryable<CustomEntityRecord> query,
            string sort,
            bool descending)
        {
            if (sort.Equals("id", StringComparison.OrdinalIgnoreCase))
                return descending ? query.OrderByDescending(r => r.Id) : query.OrderBy(r => r.Id);

            if (sort.Equals("updatedAt", StringComparison.OrdinalIgnoreCase))
                return descending ? query.OrderByDescending(r => r.UpdatedAt) : query.OrderBy(r => r.UpdatedAt);

            return descending ? query.OrderByDescending(r => r.CreatedAt) : query.OrderBy(r => r.CreatedAt);
        }

        private static string? ReadJsonField(string json, string fieldName)
        {
            if (string.IsNullOrWhiteSpace(json))
                return null;

            try
            {
                using var doc = JsonDocument.Parse(json);
                if (doc.RootElement.ValueKind != JsonValueKind.Object)
                    return null;

                if (!doc.RootElement.TryGetProperty(fieldName, out var value))
                    return null;

                return value.ValueKind switch
                {
                    JsonValueKind.String => value.GetString(),
                    JsonValueKind.Null => null,
                    _ => value.GetRawText()
                };
            }
            catch (JsonException)
            {
                return null;
            }
        }
    }
}
