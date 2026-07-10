using Church.BLL.DTOS;
using Church.BLL.DTOS.UnifiedForms;

namespace Church.BLL.Application.Servants
{
    public interface IServantProfileService
    {
        Task<ServantProfileDto> GetForCurrentUserAsync(CancellationToken cancellationToken = default);

        Task<EntityFormDataDto> GetFormDataForCurrentUserAsync(
            CancellationToken cancellationToken = default);

        Task UpdateForCurrentUserAsync(
            UpdateServantProfileCommand command,
            CancellationToken cancellationToken = default);

        Task SaveFormDataForCurrentUserAsync(
            SaveEntityFormDto dto,
            CancellationToken cancellationToken = default);
    }
}
