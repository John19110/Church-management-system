using SunDaySchools.BLL.DTOS;

namespace SunDaySchools.BLL.Application.Servants
{
    public interface IServantProfileService
    {
        Task<ServantProfileDto> GetForCurrentUserAsync(CancellationToken cancellationToken = default);
        Task UpdateForCurrentUserAsync(
            UpdateServantProfileCommand command,
            CancellationToken cancellationToken = default);
    }
}
