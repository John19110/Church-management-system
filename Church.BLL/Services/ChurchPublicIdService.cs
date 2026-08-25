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

        private static string GenerateSuffix()
        {
            Span<char> chars = stackalloc char[ChurchPublicIdPatterns.SuffixLength];
            for (var i = 0; i < ChurchPublicIdPatterns.SuffixLength; i++)
            {
                chars[i] = ChurchPublicIdPatterns.Alphabet[
                    Random.Shared.Next(ChurchPublicIdPatterns.Alphabet.Length)];
            }

            return new string(chars);
        }
    }
}
