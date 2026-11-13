using Church.DAL.Models.OptionalModules;

namespace Church.DAL.Repository.Interfaces
{
    public interface IStockItemRepository
    {
        Task<IReadOnlyList<StockItem>> GetAllAsync(string? search = null);
        Task<StockItem?> GetByIdAsync(int id);
        Task<bool> ExistsAsync(int id);
        Task AddAsync(StockItem item);
        Task UpdateAsync(StockItem item);
        Task DeleteAsync(int id);

        /// <summary>
        /// Atomically increments amount by 1. Returns the new amount, or null if the item was not found.
        /// </summary>
        Task<int?> TryIncreaseAmountAsync(int id);

        /// <summary>
        /// Atomically decrements amount by 1 when amount &gt; 0.
        /// Returns (true, newAmount) on success, (false, currentAmount) when amount is already 0,
        /// or null when the item was not found / not in tenant scope.
        /// </summary>
        Task<(bool Decreased, int Amount)?> TryDecreaseAmountAsync(int id);

        Task SaveChangesAsync();
    }
}
