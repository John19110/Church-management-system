using Church.DAL.Models;

namespace Church.BLL.Services
{
    public interface IPublicIdResolver
    {
        Task<ChurchModel?> GetChurchByPublicIdAsync(string publicId);
        Task<Meeting?> GetMeetingByPublicIdAsync(string publicId);
        Task<int?> GetChurchIdByPublicIdAsync(string publicId);
        Task<int?> GetMeetingIdByPublicIdAsync(string publicId);
    }
}
