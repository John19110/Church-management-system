using System.Security.Cryptography;
using Church.DAL.Repository.Interfaces;

namespace Church.BLL.Services
{
    public sealed class ChurchPublicIdService : IChurchPublicIdService
    {
        private const int MaxAttempts = 100;

        private readonly IChurchRepository _churchRepository;

        public ChurchPublicIdService(IChurchRepository churchRepository)
        {
            _churchRepository = churchRepository;
        }

        public bool IsShortFormat(string? publicId) =>
            ChurchPublicIdPatterns.IsShortFormat(publicId);

        public string Normalize(string publicId) =>
            ChurchPublicIdPatterns.Normalize(publicId);

        public async Task<string> GenerateUniqueAsync(
            CancellationToken cancellationToken = default)
        {
            for (var attempt = 0; attempt < MaxAttempts; attempt++)
            {
                cancellationToken.ThrowIfCancellationRequested();
                var candidate = ChurchPublicIdPatterns.Prefix + GenerateSuffix();

                if (!await _churchRepository.ExistsPublicIdAsync(candidate))
                    return candidate;
            }

            throw new InvalidOperationException("Could not generate a unique church public id.");
        }

        /// <summary>
        /// This code is the anonymous join credential for a church, so it must not be predictable.
        /// <c>Random.Shared</c> is seeded pseudo-randomness and its output can be reconstructed from
        /// observed values; use the cryptographic generator instead.
        /// </summary>
        private static string GenerateSuffix()
        {
            Span<char> chars = stackalloc char[ChurchPublicIdPatterns.SuffixLength];
            for (var i = 0; i < ChurchPublicIdPatterns.SuffixLength; i++)
            {
                chars[i] = ChurchPublicIdPatterns.Alphabet[
                    RandomNumberGenerator.GetInt32(ChurchPublicIdPatterns.Alphabet.Length)];
            }

            return new string(chars);
        }
    }
}
