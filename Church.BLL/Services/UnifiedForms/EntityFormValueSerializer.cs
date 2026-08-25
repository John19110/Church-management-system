using System.Globalization;
using System.Text.Json;
using Church.BLL.DTOS;

namespace Church.BLL.Services.UnifiedForms
{
    public static class EntityFormValueSerializer
    {
        public static int? ParseInt(string? value) =>
            int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var n) ? n : null;

        public static List<int>? ParseIntList(string? value)
        {
            if (string.IsNullOrWhiteSpace(value))
                return null;

            var trimmed = value.Trim();
            if (trimmed.StartsWith('['))
            {
                try
                {
                    using var doc = JsonDocument.Parse(trimmed);
                    if (doc.RootElement.ValueKind != JsonValueKind.Array)
                        return null;

                    return doc.RootElement.EnumerateArray()
                        .Select(ParseJsonInt)
                        .Where(n => n > 0)
                        .Distinct()
                        .ToList();
                }
                catch
                {
                    return null;
                }
            }

            return trimmed
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .Select(s => int.TryParse(s, NumberStyles.Integer, CultureInfo.InvariantCulture, out var n) ? n : 0)
                .Where(n => n > 0)
                .Distinct()
                .ToList();
        }

        private static int ParseJsonInt(JsonElement element) =>
            element.ValueKind switch
            {
                JsonValueKind.Number => element.TryGetInt32(out var n) ? n : 0,
                JsonValueKind.String => int.TryParse(
                    element.GetString(),
                    NumberStyles.Integer,
                    CultureInfo.InvariantCulture,
                    out var parsed)
                    ? parsed
                    : 0,
                _ => 0
            };

        public static bool? ParseBool(string? value)
        {
            if (string.IsNullOrWhiteSpace(value)) return null;
            if (bool.TryParse(value, out var b)) return b;
            return value is "1" or "yes" or "true";
        }

        public static DateOnly? ParseDate(string? value) =>
            DateOnly.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.None, out var d) ? d : null;

        public static List<string>? ParseStringList(string? value)
        {
            if (string.IsNullOrWhiteSpace(value)) return null;
            try
            {
                return JsonSerializer.Deserialize<List<string>>(value);
            }
            catch
            {
                return value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                    .ToList();
            }
        }

        public static List<MemberContactDTO>? ParsePhoneNumbers(string? value)
        {
            if (string.IsNullOrWhiteSpace(value)) return null;
            try
            {
                return JsonSerializer.Deserialize<List<MemberContactDTO>>(value);
            }
            catch
            {
                return null;
            }
        }
    }
}
