using Church.BLL.DTOS.OptionalModules;

namespace Church.BLL.Manager.Interfaces
{
    public interface IStockItemManager
    {
        Task<IReadOnlyList<StockItemReadDto>> GetAllAsync(string? search = null);
        Task<StockItemReadDto?> GetByIdAsync(int id);
        Task<StockItemReadDto> CreateAsync(StockItemCreateDto dto);
        Task<StockItemReadDto> UpdateAsync(int id, StockItemUpdateDto dto);
        Task DeleteAsync(int id);
        Task UpdateImageAsync(int id, string fileName, string publicUrl);
        Task<StockAmountChangeResultDto> IncreaseAmountAsync(int id);
        Task<StockAmountChangeResultDto> DecreaseAmountAsync(int id);
    }
}
