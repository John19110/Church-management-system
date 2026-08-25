namespace Church.BLL.Services
{
    internal static class ChurchPublicIdPatterns
    {
        internal const string Prefix = "C";
        internal const string Alphabet = "0123456789ABCDEFGHJKLMNPQRSTUVWXYZ";
        internal const int SuffixLength = 5;

        internal static bool IsShortFormat(string? publicId)
        {
            if (string.IsNullOrWhiteSpace(publicId))
                return false;

            var normalized = publicId.Trim().ToUpperInvariant();
            if (normalized.Length != Prefix.Length + SuffixLength)
                return false;

            if (!normalized.StartsWith(Prefix, StringComparison.Ordinal))
                return false;

            for (var i = Prefix.Length; i < normalized.Length; i++)
            {
                if (!Alphabet.Contains(normalized[i]))
                    return false;
            }

            return true;
        }

        internal static string Normalize(string publicId) => publicId.Trim().ToUpperInvariant();
    }
}
