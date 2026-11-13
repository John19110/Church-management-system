using Church.DAL.DBcontext;
using Church.DAL.Models.CustomFields;
using Church.DAL.Models.OptionalModules;
using Church.DAL.Repository.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Church.DAL.Repository.Implementations
{
    public class StockItemRepository : IStockItemRepository
    {
        private readonly ProgramContext _context;

        public StockItemRepository(ProgramContext context)
        {
            _context = context;
        }

        public async Task<IReadOnlyList<StockItem>> GetAllAsync(string? search = null)
        {
            var query = _context.StockItems.AsNoTracking().AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search.Trim();
                query = query.Where(i =>
                    i.Name.Contains(term) ||
                    (i.NameAr != null && i.NameAr.Contains(term)) ||
                    (i.Description != null && i.Description.Contains(term)) ||
                    (i.DescriptionAr != null && i.DescriptionAr.Contains(term)));
            }

            return await query
                .OrderBy(i => i.Name)
                .ToListAsync();
        }

        public async Task<StockItem?> GetByIdAsync(int id)
        {
            return await _context.StockItems.FirstOrDefaultAsync(i => i.Id == id);
        }

        public async Task<bool> ExistsAsync(int id)
        {
            return await _context.StockItems.AnyAsync(i => i.Id == id);
        }

        public async Task AddAsync(StockItem item)
        {
            await _context.StockItems.AddAsync(item);
        }

        public async Task UpdateAsync(StockItem item)
        {
            var entry = _context.Entry(item);
            if (entry.State == EntityState.Detached)
                _context.StockItems.Update(item);
        }

        public async Task DeleteAsync(int id)
        {
            await _context.CustomFieldValues
                .IgnoreQueryFilters()
                .Where(v =>
                    v.EntityName == CustomFieldEntityNames.StockItem &&
                    v.EntityId == id)
                .ExecuteDeleteAsync();

            await _context.StockItems
                .Where(i => i.Id == id)
                .ExecuteDeleteAsync();
        }

        public async Task<int?> TryIncreaseAmountAsync(int id)
        {
            var now = DateTime.UtcNow;
            var rows = await _context.StockItems
                .Where(i => i.Id == id)
                .ExecuteUpdateAsync(s => s
                    .SetProperty(i => i.Amount, i => i.Amount + 1)
                    .SetProperty(i => i.UpdatedAtUtc, now));

            if (rows == 0)
                return null;

            DetachLocalStockItem(id);

            return await _context.StockItems
                .AsNoTracking()
                .Where(i => i.Id == id)
                .Select(i => i.Amount)
                .FirstOrDefaultAsync();
        }

        public async Task<(bool Decreased, int Amount)?> TryDecreaseAmountAsync(int id)
        {
            var now = DateTime.UtcNow;
            var rows = await _context.StockItems
                .Where(i => i.Id == id && i.Amount > 0)
                .ExecuteUpdateAsync(s => s
                    .SetProperty(i => i.Amount, i => i.Amount - 1)
                    .SetProperty(i => i.UpdatedAtUtc, now));

            DetachLocalStockItem(id);

            if (rows > 0)
            {
                var amount = await _context.StockItems
                    .AsNoTracking()
                    .Where(i => i.Id == id)
                    .Select(i => i.Amount)
                    .FirstAsync();
                return (true, amount);
            }

            var existing = await _context.StockItems
                .AsNoTracking()
                .Where(i => i.Id == id)
                .Select(i => (int?)i.Amount)
                .FirstOrDefaultAsync();

            if (existing is null)
                return null;

            return (false, existing.Value);
        }

        /// <summary>
        /// ExecuteUpdate bypasses the change tracker; detach any local copy so
        /// subsequent reads do not return a stale Amount.
        /// </summary>
        private void DetachLocalStockItem(int id)
        {
            var local = _context.StockItems.Local.FirstOrDefault(i => i.Id == id);
            if (local != null)
                _context.Entry(local).State = EntityState.Detached;
        }

        public async Task SaveChangesAsync()
        {
            await _context.SaveChangesAsync();
        }
    }
}
