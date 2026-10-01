namespace Church.BLL.Services
{
    /// <summary>
    /// Church supported languages vs user preferred language. Codes are <c>en</c> and <c>ar</c>.
    /// </summary>
    public static class OrganizationLanguages
    {
        public const string English = "en";
        public const string Arabic = "ar";
        public const string DefaultSupportedSerialized = "en,ar";
        public const string DefaultFallback = English;

        public static string Normalize(string? code)
        {
            var value = (code ?? string.Empty).Trim().ToLowerInvariant();
            if (value is "ar" or "arabic" or "العربية")
                return Arabic;
            if (value is "en" or "english")
                return English;
            return string.Empty;
        }

        public static IReadOnlyList<string> ParseSupported(string? raw)
        {
            if (string.IsNullOrWhiteSpace(raw))
                return new[] { English, Arabic };

            var codes = raw
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .Select(Normalize)
                .Where(code => code is English or Arabic)
                .Distinct(StringComparer.Ordinal)
                .ToList();

            return codes.Count == 0 ? new[] { English, Arabic } : codes;
        }

        public static string Serialize(IEnumerable<string>? codes)
        {
            var parsed = (codes ?? Array.Empty<string>())
                .Select(Normalize)
                .Where(code => code is English or Arabic)
                .Distinct(StringComparer.Ordinal)
                .ToList();

            if (parsed.Count == 0)
                parsed.AddRange(new[] { English, Arabic });

            return string.Join(',', parsed);
        }

        public static string NormalizeDefault(string? defaultCode, IReadOnlyList<string> supported)
        {
            var code = Normalize(defaultCode);
            if (supported.Contains(code, StringComparer.Ordinal))
                return code;
            return supported.Count > 0 ? supported[0] : DefaultFallback;
        }

        public static string? NormalizePreferred(string? preferred, IReadOnlyList<string> supported)
        {
            var code = Normalize(preferred);
            if (code.Length == 0)
                return null;
            return supported.Contains(code, StringComparer.Ordinal) ? code : null;
        }

        /// <summary>
        /// Application UI language. Independent of church customization SupportedLanguages.
        /// </summary>
        public static string? NormalizeUiLanguage(string? preferred)
        {
            var code = Normalize(preferred);
            return code.Length == 0 ? null : code;
        }

        public static (string Supported, string Default) FromRegistration(
            string? supportedRaw,
            string? defaultRaw)
        {
            var supported = ParseSupported(supportedRaw);
            var fallback = NormalizeDefault(defaultRaw, supported);
            return (Serialize(supported), fallback);
        }
    }
}
