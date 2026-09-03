using System.Security.Cryptography;
using Church.DAL.Repository.Interfaces;

namespace Church.BLL.Services
{
    public sealed class MeetingPublicIdService : IMeetingPublicIdService
    {
        private const int MaxAttempts = 100;

        private readonly IMeetingRepository _meetingRepository;

        public MeetingPublicIdService(IMeetingRepository meetingRepository)
        {
            _meetingRepository = meetingRepository;
        }

        public bool IsShortFormat(string? publicId) => MeetingPublicIdPatterns.IsShortFormat(publicId);

        public string Normalize(string publicId) => MeetingPublicIdPatterns.Normalize(publicId);

        public async Task<string> GenerateUniqueAsync(
            int churchId,
            CancellationToken cancellationToken = default)
        {
            for (var attempt = 0; attempt < MaxAttempts; attempt++)
            {
                cancellationToken.ThrowIfCancellationRequested();
                var candidate = MeetingPublicIdPatterns.Prefix + GenerateSuffix();

                if (await _meetingRepository.ExistsPublicIdInChurchAsync(churchId, candidate))
                    continue;

                if (await _meetingRepository.ExistsPublicIdAsync(candidate))
                    continue;

                return candidate;
            }

            throw new InvalidOperationException("Could not generate a unique meeting public id.");
        }

        /// <summary>
        /// This code is the anonymous join credential for a meeting, so it must not be predictable.
        /// <c>Random.Shared</c> is seeded pseudo-randomness and its output can be reconstructed from
        /// observed values; use the cryptographic generator instead.
        /// </summary>
        private static string GenerateSuffix()
        {
            Span<char> chars = stackalloc char[MeetingPublicIdPatterns.SuffixLength];
            for (var i = 0; i < MeetingPublicIdPatterns.SuffixLength; i++)
            {
                chars[i] = MeetingPublicIdPatterns.Alphabet[
                    RandomNumberGenerator.GetInt32(MeetingPublicIdPatterns.Alphabet.Length)];
            }

            return new string(chars);
        }
    }
}
