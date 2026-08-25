using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace Church.BLL.Services.CustomFields
{
    public static class CustomFieldNameGenerator
    {
        public static string GenerateBaseName(string displayName)
        {
            if (string.IsNullOrWhiteSpace(displayName))
                return "field";

            var normalized = displayName.Trim().ToLowerInvariant();
            normalized = Regex.Replace(normalized, @"[^a-z0-9]+", "_");
            normalized = normalized.Trim('_');
            if (normalized.Length == 0)
                return "field";
            if (!char.IsLetter(normalized[0]))
                normalized = "f_" + normalized;
            return normalized.Length > 64 ? normalized[..64] : normalized;
        }

        public static string EnsureUnique(string baseName, ISet<string> existing)
        {
            if (!existing.Contains(baseName))
                return baseName;

            for (var i = 2; i < 1000; i++)
            {
                var candidate = $"{baseName}_{i}";
                if (!existing.Contains(candidate))
                    return candidate;
            }

            return $"{baseName}_{Guid.NewGuid():N}"[..64];
        }
    }
}
