using Church.DAL.Models.OptionalModules;

namespace Church.DAL.Repository.Interfaces
{
    public interface IOptionalModuleRepository
    {
        Task<IReadOnlyList<OrganizationModuleActivation>> GetActivationsAsync();
        Task<OrganizationModuleActivation?> GetActivationForScopeAsync(string moduleId, int? meetingId);
        Task AddActivationAsync(OrganizationModuleActivation activation);
        Task UpdateActivationAsync(OrganizationModuleActivation activation);
        Task SaveChangesAsync();
    }
}
