using System.Globalization;
using System.Text.Json;
using System.Text.RegularExpressions;
using Church.DAL.Models.CustomFeatures;

namespace Church.BLL.Services.CustomFeatures
{
    public static class CustomEntityRecordValidator
    {
        public const int MaxJsonBytes = 64 * 1024;

        public static bool TryValidateScalar(
            CustomEntityField field,
            object? raw,
            out string? normalized,
            out string error)
        {
            normalized = null;
            error = string.Empty;
            var text = NormalizeRaw(raw);

            if (field.IsRequired && string.IsNullOrWhiteSpace(text))
            {
                error = $"{field.DisplayName} is required.";
                return false;
            }

            if (string.IsNullOrWhiteSpace(text))
                return true;

            if (!string.IsNullOrWhiteSpace(field.ValidationRegex) &&
                !Regex.IsMatch(text, field.ValidationRegex))
            {
                error = $"{field.DisplayName} has an invalid format.";
                return false;
            }

            var allowed = field.Options
                .Select(o => o.Value)
                .ToHashSet(StringComparer.OrdinalIgnoreCase);

            if (!CanParse(field.FieldType, text, allowed))
            {
                error = $"{field.DisplayName} is not a valid {field.FieldType} value.";
                return false;
            }

            normalized = Normalize(field.FieldType, text);
            return true;
        }

        public static IReadOnlyList<int> ParseIdList(object? raw)
        {
            if (raw is null)
                return Array.Empty<int>();

            if (raw is JsonElement element)
            {
                if (element.ValueKind == JsonValueKind.Number && element.TryGetInt32(out var one))
                    return one > 0 ? new[] { one } : Array.Empty<int>();

                if (element.ValueKind == JsonValueKind.String)
                    return ParseIdList(element.GetString());

                if (element.ValueKind == JsonValueKind.Array)
                {
                    return element.EnumerateArray()
                        .Select(ParseElementId)
                        .Where(id => id > 0)
                        .Distinct()
                        .ToList();
                }
            }

            if (raw is IEnumerable<object> list && raw is not string)
            {
                return list.Select(item => ParseIdList(item).FirstOrDefault())
                    .Where(id => id > 0)
                    .Distinct()
                    .ToList();
            }

            var text = NormalizeRaw(raw);
            if (string.IsNullOrWhiteSpace(text))
                return Array.Empty<int>();

            if (text.StartsWith('['))
            {
                try
                {
                    return JsonSerializer.Deserialize<List<int>>(text)
                        ?.Where(id => id > 0)
                        .Distinct()
                        .ToList()
                        ?? new List<int>();
                }
                catch (JsonException)
                {
                    return Array.Empty<int>();
                }
            }

            return int.TryParse(text, NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed) && parsed > 0
                ? new[] { parsed }
                : Array.Empty<int>();
        }

        private static int ParseElementId(JsonElement element)
        {
            if (element.ValueKind == JsonValueKind.Number && element.TryGetInt32(out var n))
                return n;
            if (element.ValueKind == JsonValueKind.String &&
                int.TryParse(element.GetString(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed))
                return parsed;
            return 0;
        }

        private static string? NormalizeRaw(object? raw)
        {
            if (raw is null)
                return null;

            if (raw is JsonElement element)
            {
                return element.ValueKind switch
                {
                    JsonValueKind.Null => null,
                    JsonValueKind.String => element.GetString(),
                    JsonValueKind.True => "true",
                    JsonValueKind.False => "false",
                    JsonValueKind.Number => element.GetRawText(),
                    _ => element.GetRawText()
                };
            }

            return Convert.ToString(raw, CultureInfo.InvariantCulture);
        }

        private static bool CanParse(
            CustomEntityFieldType type,
            string value,
            IReadOnlySet<string> allowed)
        {
            return type switch
            {
                CustomEntityFieldType.Text or CustomEntityFieldType.LongText
                    or CustomEntityFieldType.Phone or CustomEntityFieldType.Url => true,
                CustomEntityFieldType.Number => int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out _),
                CustomEntityFieldType.Decimal => decimal.TryParse(value, NumberStyles.Number, CultureInfo.InvariantCulture, out _),
                CustomEntityFieldType.Boolean => bool.TryParse(value, out _) || value is "0" or "1",
                CustomEntityFieldType.Date => DateOnly.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.None, out _),
                CustomEntityFieldType.Time => TimeOnly.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.None, out _),
                CustomEntityFieldType.DateTime => DateTime.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.None, out _),
                CustomEntityFieldType.Email => value.Contains('@', StringComparison.Ordinal),
                CustomEntityFieldType.Dropdown => allowed.Count == 0 || allowed.Contains(value),
                CustomEntityFieldType.MultiSelect => ParseMultiSelect(value).All(v => allowed.Count == 0 || allowed.Contains(v)),
                _ => true
            };
        }

        private static string Normalize(CustomEntityFieldType type, string value)
        {
            return type switch
            {
                CustomEntityFieldType.Boolean when value is "1" => "true",
                CustomEntityFieldType.Boolean when value is "0" => "false",
                CustomEntityFieldType.MultiSelect => JsonSerializer.Serialize(ParseMultiSelect(value)),
                _ => value
            };
        }

        private static IEnumerable<string> ParseMultiSelect(string value)
        {
            if (value.StartsWith('['))
            {
                try
                {
                    return JsonSerializer.Deserialize<List<string>>(value) ?? new List<string>();
                }
                catch (JsonException)
                {
                    return Array.Empty<string>();
                }
            }

            return value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        }
    }
}
