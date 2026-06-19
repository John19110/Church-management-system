using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.UnifiedForms;

namespace SunDaySchools.BLL.Application.Servants
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
