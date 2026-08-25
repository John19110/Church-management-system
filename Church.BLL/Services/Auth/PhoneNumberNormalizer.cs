using System.Text.RegularExpressions;

namespace Church.BLL.Services.Auth
{
    /// <summary>
    /// Validates and normalizes phone numbers for storage (digits with country code, no '+').
    /// Prefers E.164-compatible input (e.g. +201001234567).
    /// </summary>
    public static class PhoneNumberNormalizer
    {
        private static readonly Regex AllowedInputChars =
            new(@"^[\d\s\-\(\)\.+]+$", RegexOptions.Compiled);

        private static readonly Regex DigitsOnly =
            new(@"\D", RegexOptions.Compiled);

        /// <summary>
        /// Canonical storage format: country code + national number, digits only (no '+').
        /// </summary>
        public static string Normalize(string? phoneNumber, string defaultCountryCode = "20")
        {
            if (!TryNormalize(phoneNumber, out var normalized, defaultCountryCode))
                throw new ArgumentException("Phone number is invalid.", nameof(phoneNumber));

            return normalized;
        }

        public static bool TryNormalize(
            string? phoneNumber,
            out string normalized,
            string defaultCountryCode = "20")
        {
            normalized = string.Empty;

            if (string.IsNullOrWhiteSpace(phoneNumber))
                return false;

            var trimmed = phoneNumber.Trim();

            // Reject letters / unsupported symbols. Only digits, spaces, - ( ) . and a leading +.
            if (!AllowedInputChars.IsMatch(trimmed))
                return false;

            var plusCount = trimmed.Count(c => c == '+');
            if (plusCount > 1)
                return false;
            if (plusCount == 1 && !trimmed.StartsWith('+'))
                return false;

            var digits = DigitsOnly.Replace(trimmed, "");
            if (digits.Length == 0)
                return false;

            // Strip trunk 0, then ensure country code.
            if (digits.StartsWith('0') && digits.Length > 1)
                digits = defaultCountryCode + digits[1..];
            else if (!digits.StartsWith(defaultCountryCode, StringComparison.Ordinal)
                     && digits.Length <= 11)
                digits = defaultCountryCode + digits;

            // E.164 national significant number is at most 15 digits total.
            if (digits.Length < 10 || digits.Length > 15)
                return false;

            // Egyptian mobiles: 20 + 10 digits starting with 1 (e.g. 2010…).
            if (digits.StartsWith(defaultCountryCode, StringComparison.Ordinal)
                && defaultCountryCode == "20")
            {
                var national = digits[defaultCountryCode.Length..];
                if (national.Length != 10 || national[0] != '1')
                    return false;
            }

            normalized = digits;
            return true;
        }

        /// <summary>
        /// Formats to match values that may already exist in the database.
        /// </summary>
        public static IReadOnlyCollection<string> GetLookupCandidates(
            string? phoneNumber,
            string defaultCountryCode = "20")
        {
            if (string.IsNullOrWhiteSpace(phoneNumber))
                return Array.Empty<string>();

            var trimmed = phoneNumber.Trim();
            var digits = DigitsOnly.Replace(trimmed, "");
            if (digits.Length == 0)
                return Array.Empty<string>();

            var candidates = new HashSet<string>(StringComparer.Ordinal)
            {
                trimmed,
                digits
            };

            if (digits.StartsWith('0') && digits.Length > 1)
                candidates.Add(defaultCountryCode + digits[1..]);

            if (digits.StartsWith(defaultCountryCode, StringComparison.Ordinal)
                && digits.Length > defaultCountryCode.Length)
            {
                candidates.Add("0" + digits[defaultCountryCode.Length..]);
                candidates.Add("+" + digits);
            }

            if (TryNormalize(trimmed, out var normalized, defaultCountryCode))
            {
                candidates.Add(normalized);
                candidates.Add("+" + normalized);
            }

            return candidates;
        }

        public static string ToE164(string normalizedDigits) =>
            normalizedDigits.StartsWith('+') ? normalizedDigits : $"+{normalizedDigits}";
    }
}
