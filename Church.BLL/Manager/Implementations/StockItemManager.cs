using Church.BLL.Abstractions;
using Church.BLL.Authorization;
using Church.BLL.DTOS.OptionalModules;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;
using Church.BLL.OptionalModules;
using Church.DAL.Abstractions;
using Church.DAL.Models.OptionalModules;
using Church.DAL.Repository.Interfaces;

namespace Church.BLL.Manager.Implementations
{
    public class StockItemManager : IStockItemManager
    {
        private readonly IStockItemRepository _repository;
        private readonly IOptionalModuleManager _optionalModules;
        private readonly ITenantContext _tenantContext;
        private readonly ICurrentUserContext _currentUser;

        public StockItemManager(
            IStockItemRepository repository,
            IOptionalModuleManager optionalModules,
            ITenantContext tenantContext,
            ICurrentUserContext currentUser)
        {
            _repository = repository;
            _optionalModules = optionalModules;
            _tenantContext = tenantContext;
            _currentUser = currentUser;
        }

        public async Task<IReadOnlyList<StockItemReadDto>> GetAllAsync(string? search = null)
        {
            await EnsureStockEnabledAsync();
            var items = await _repository.GetAllAsync(search);
            return items.Select(ToDto).ToList();
        }

        public async Task<StockItemReadDto?> GetByIdAsync(int id)
        {
            await EnsureStockEnabledAsync();
            var item = await _repository.GetByIdAsync(id);
            return item == null ? null : ToDto(item);
        }

        public async Task<StockItemReadDto> CreateAsync(StockItemCreateDto dto)
        {
            await EnsureStockEnabledAsync();
            EnsureCanManageStock();
            ValidateWrite(dto.Name, dto.Amount);

            var item = new StockItem
            {
                Name = dto.Name.Trim(),
                NameAr = EmptyToNull(dto.NameAr),
                Description = EmptyToNull(dto.Description),
                DescriptionAr = EmptyToNull(dto.DescriptionAr),
                Amount = dto.Amount,
                CreatedAtUtc = DateTime.UtcNow,
                CreatedBy = _currentUser.UserId,
                ChurchId = RequireChurchId(),
                MeetingId = ResolveCreatedMeetingId()
            };

            await _repository.AddAsync(item);
            await _repository.SaveChangesAsync();
            return ToDto(item);
        }

        public async Task<StockItemReadDto> UpdateAsync(int id, StockItemUpdateDto dto)
        {
            await EnsureStockEnabledAsync();
            EnsureCanManageStock();
            ValidateWrite(dto.Name, dto.Amount);

            var item = await _repository.GetByIdAsync(id)
                ?? throw new NotFoundException("Stock item not found.");

            item.Name = dto.Name.Trim();
            item.NameAr = EmptyToNull(dto.NameAr);
            item.Description = EmptyToNull(dto.Description);
            item.DescriptionAr = EmptyToNull(dto.DescriptionAr);
            item.Amount = dto.Amount;
            item.UpdatedAtUtc = DateTime.UtcNow;

            await _repository.UpdateAsync(item);
            await _repository.SaveChangesAsync();
            return ToDto(item);
        }

        public async Task DeleteAsync(int id)
        {
            await EnsureStockEnabledAsync();
            EnsureCanManageStock();

            if (!await _repository.ExistsAsync(id))
                throw new NotFoundException("Stock item not found.");

            await _repository.DeleteAsync(id);
        }

        public async Task UpdateImageAsync(int id, string fileName, string publicUrl)
        {
            await EnsureStockEnabledAsync();
            EnsureCanManageStock();

            var item = await _repository.GetByIdAsync(id)
                ?? throw new NotFoundException("Stock item not found.");

            item.ImageFileName = fileName;
            item.ImageUrl = publicUrl;
            item.UpdatedAtUtc = DateTime.UtcNow;

            await _repository.UpdateAsync(item);
            await _repository.SaveChangesAsync();
        }

        public async Task<StockAmountChangeResultDto> IncreaseAmountAsync(int id)
        {
            await EnsureStockEnabledAsync();
            EnsureCanManageStock();

            var newAmount = await _repository.TryIncreaseAmountAsync(id);
            if (newAmount is null)
                throw new NotFoundException("Stock item not found.");

            return new StockAmountChangeResultDto { Id = id, Amount = newAmount.Value };
        }

        public async Task<StockAmountChangeResultDto> DecreaseAmountAsync(int id)
        {
            await EnsureStockEnabledAsync();
            EnsureCanManageStock();

            var result = await _repository.TryDecreaseAmountAsync(id);
            if (result is null)
                throw new NotFoundException("Stock item not found.");

            if (!result.Value.Decreased)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["amount"] = new[] { "Quantity cannot be decreased below zero." }
                });
            }

            return new StockAmountChangeResultDto { Id = id, Amount = result.Value.Amount };
        }

        private async Task EnsureStockEnabledAsync()
        {
            EnsureAuthenticated();
            await _optionalModules.EnsureModuleEnabledAsync(PredefinedModules.Stock);
        }

        private void EnsureCanManageStock()
        {
            if (!_currentUser.IsInRole(OptionalModuleRoles.SuperAdmin) &&
                !_currentUser.IsInRole(OptionalModuleRoles.Admin) &&
                !_currentUser.IsInRole(OptionalModuleRoles.Servant))
            {
                throw new UnauthorizedAccessException("You are not authorized to manage stock.");
            }
        }

        private void EnsureAuthenticated()
        {
            if (!_currentUser.IsAuthenticated)
                throw new UnauthorizedAccessException("Authentication required.");
        }

        private int RequireChurchId() =>
            _tenantContext.ChurchId
            ?? throw new UnauthorizedAccessException("Church context is required.");

        private int? ResolveCreatedMeetingId() =>
            _currentUser.IsInRole(OptionalModuleRoles.SuperAdmin)
                ? null
                : _tenantContext.MeetingId;

        private static void ValidateWrite(string name, int amount)
        {
            var errors = new Dictionary<string, string[]>();
            if (string.IsNullOrWhiteSpace(name))
                errors["name"] = new[] { "Name is required." };
            if (amount < 0)
                errors["amount"] = new[] { "Amount cannot be negative." };

            if (errors.Count > 0)
                throw new ValidationException(errors);
        }

        private static string? EmptyToNull(string? value) =>
            string.IsNullOrWhiteSpace(value) ? null : value.Trim();

        private static StockItemReadDto ToDto(StockItem item) =>
            new()
            {
                Id = item.Id,
                Name = item.Name,
                NameAr = item.NameAr,
                Description = item.Description,
                DescriptionAr = item.DescriptionAr,
                Amount = item.Amount,
                ImageUrl = item.ImageUrl,
                CreatedAtUtc = item.CreatedAtUtc,
                UpdatedAtUtc = item.UpdatedAtUtc
            };
    }
}
