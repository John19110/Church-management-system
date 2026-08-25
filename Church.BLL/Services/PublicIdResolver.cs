using Church.DAL.Models;
using Church.DAL.Repository.Interfaces;

namespace Church.BLL.Services
{
    public class PublicIdResolver : IPublicIdResolver
    {
        private readonly IChurchRepository _churchRepository;
        private readonly IMeetingRepository _meetingRepository;
        private readonly IChurchPublicIdService _churchPublicIdService;
        private readonly IMeetingPublicIdService _meetingPublicIdService;

        public PublicIdResolver(
            IChurchRepository churchRepository,
            IMeetingRepository meetingRepository,
            IChurchPublicIdService churchPublicIdService,
            IMeetingPublicIdService meetingPublicIdService)
        {
            _churchRepository = churchRepository;
            _meetingRepository = meetingRepository;
            _churchPublicIdService = churchPublicIdService;
            _meetingPublicIdService = meetingPublicIdService;
        }

        public Task<ChurchModel?> GetChurchByPublicIdAsync(string publicId)
        {
            if (!PublicIdHelper.IsValidChurchPublicId(publicId))
                return Task.FromResult<ChurchModel?>(null);

            var normalized = _churchPublicIdService.IsShortFormat(publicId)
                ? _churchPublicIdService.Normalize(publicId)
                : PublicIdHelper.Normalize(publicId);

            return _churchRepository.GetByPublicIdAsync(normalized);
        }

        public Task<Meeting?> GetMeetingByPublicIdAsync(string publicId)
        {
            if (!PublicIdHelper.IsValidMeetingPublicId(publicId))
                return Task.FromResult<Meeting?>(null);

            var normalized = _meetingPublicIdService.IsShortFormat(publicId)
                ? _meetingPublicIdService.Normalize(publicId)
                : PublicIdHelper.Normalize(publicId);

            return _meetingRepository.GetByPublicIdAsync(normalized);
        }

        public Task<int?> GetChurchIdByPublicIdAsync(string publicId)
        {
            if (!PublicIdHelper.IsValidChurchPublicId(publicId))
                return Task.FromResult<int?>(null);

            var normalized = _churchPublicIdService.IsShortFormat(publicId)
                ? _churchPublicIdService.Normalize(publicId)
                : PublicIdHelper.Normalize(publicId);

            return _churchRepository.GetChurchIdByPublicIdAsync(normalized);
        }

        public Task<int?> GetMeetingIdByPublicIdAsync(string publicId)
        {
            if (!PublicIdHelper.IsValidMeetingPublicId(publicId))
                return Task.FromResult<int?>(null);

            var normalized = _meetingPublicIdService.IsShortFormat(publicId)
                ? _meetingPublicIdService.Normalize(publicId)
                : PublicIdHelper.Normalize(publicId);

            return _meetingRepository.GetMeetingIdByPublicIdAsync(normalized);
        }
    }
}
