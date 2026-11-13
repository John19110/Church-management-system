using Church.BLL.DTOS.OptionalModules;

namespace Church.BLL.Manager.Interfaces
{
    public interface IOptionalModuleManager
    {
        Task<IReadOnlyList<OptionalModuleReadDto>> GetModulesAsync();
        Task<OptionalModuleReadDto> SetEnabledAsync(string moduleId, bool isEnabled);
        Task<bool> IsModuleEnabledAsync(string moduleId);
        Task EnsureModuleEnabledAsync(string moduleId);
    }
}
