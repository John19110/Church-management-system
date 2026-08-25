using System.Globalization;
using System.Text.Json;
using System.Text.RegularExpressions;
using Church.BLL.Services.UnifiedForms;
using Church.DAL.Models.CustomFields;

namespace Church.BLL.Services.CustomFields
{
    public class CustomFieldValidator : ICustomFieldValidator
    {
        public bool TryValidateValue(
            CustomFieldDefinition definition,
            string? rawValue,
            out string? normalizedValue,
            out string errorMessage)
        {
            normalizedValue = rawValue?.Trim();
            errorMessage = string.Empty;

            if (definition.IsRequired && string.IsNullOrWhiteSpace(normalizedValue))
            {
                errorMessage = $"{definition.DisplayName} is required.";
                return false;
            }

            if (string.IsNullOrWhiteSpace(normalizedValue))
            {
                normalizedValue = null;
                return true;
            }

            if (!string.IsNullOrWhiteSpace(definition.ValidationRegex) &&
                !Regex.IsMatch(normalizedValue, definition.ValidationRegex))
            {
                errorMessage = $"{definition.DisplayName} has an invalid format.";
                return false;
            }

            var lookupEndpoint = EntityDefaultFieldTemplates
                .FindTemplate(definition.EntityName, definition.Name)
                ?.LookupEndpoint;
            if (definition.DataType == CustomFieldDataType.SingleSelect &&
                !string.IsNullOrWhiteSpace(lookupEndpoint))
            {
                if (!int.TryParse(
                        normalizedValue,
                        NumberStyles.Integer,
                        CultureInfo.InvariantCulture,
                        out var lookupId) ||
                    lookupId <= 0)
                {
                    errorMessage = $"{definition.DisplayName} is not a valid {definition.DataType} value.";
                    return false;
                }

                normalizedValue = lookupId.ToString(CultureInfo.InvariantCulture);
                return true;
            }

            if (definition.DataType == CustomFieldDataType.MultiSelect &&
                !string.IsNullOrWhiteSpace(lookupEndpoint))
            {
                var ids = ParseMultiSelect(normalizedValue)
                    .Select(v => int.TryParse(v, NumberStyles.Integer, CultureInfo.InvariantCulture, out var n) ? n : 0)
                    .Where(n => n > 0)
                    .Distinct()
                    .ToList();

                normalizedValue = JsonSerializer.Serialize(ids);
                return true;
            }

            var allowed = GetAllowedOptionValues(definition);
            if (!CanParseAsType(definition.DataType, normalizedValue, allowed))
            {
                errorMessage = $"{definition.DisplayName} is not a valid {definition.DataType} value.";
                return false;
            }

            normalizedValue = Normalize(definition.DataType, normalizedValue, allowed);
            return true;
        }

        public bool CanParseAsType(
            CustomFieldDataType dataType,
            string? rawValue,
            IReadOnlySet<string>? allowedOptionValues)
        {
            if (string.IsNullOrWhiteSpace(rawValue))
                return true;

            return dataType switch
            {
                CustomFieldDataType.Text or CustomFieldDataType.LongText => true,
                CustomFieldDataType.Number => int.TryParse(rawValue, NumberStyles.Integer, CultureInfo.InvariantCulture, out _),
                CustomFieldDataType.Decimal => decimal.TryParse(rawValue, NumberStyles.Number, CultureInfo.InvariantCulture, out _),
                CustomFieldDataType.Boolean => bool.TryParse(rawValue, out _) || rawValue is "0" or "1",
                CustomFieldDataType.Date => DateOnly.TryParse(rawValue, CultureInfo.InvariantCulture, DateTimeStyles.None, out _),
                CustomFieldDataType.DateTime => DateTime.TryParse(rawValue, CultureInfo.InvariantCulture, DateTimeStyles.None, out _),
                CustomFieldDataType.Json => IsValidJson(rawValue),
                CustomFieldDataType.SingleSelect => allowedOptionValues == null || allowedOptionValues.Contains(rawValue),
                CustomFieldDataType.MultiSelect => ParseMultiSelect(rawValue).All(v => allowedOptionValues == null || allowedOptionValues.Contains(v)),
                _ => true,
            };
        }

        public IReadOnlySet<string> GetAllowedOptionValues(CustomFieldDefinition definition) =>
            definition.Options
                .Select(o => o.Value)
                .ToHashSet(StringComparer.OrdinalIgnoreCase);

        private static string? Normalize(
            CustomFieldDataType dataType,
            string value,
            IReadOnlySet<string>? allowedOptionValues)
        {
            return dataType switch
            {
                CustomFieldDataType.Boolean when value is "1" => "true",
                CustomFieldDataType.Boolean when value is "0" => "false",
                CustomFieldDataType.MultiSelect => JsonSerializer.Serialize(ParseMultiSelect(value)),
                _ => value,
            };
        }

        private static bool IsValidJson(string value)
        {
            try
            {
                JsonDocument.Parse(value);
                return true;
            }
            catch
            {
                return false;
            }
        }

        private static IEnumerable<string> ParseMultiSelect(string value)
        {
            if (value.StartsWith('['))
            {
                try
                {
                    return JsonSerializer.Deserialize<List<string>>(value) ?? new List<string>();
                }
                catch
                {
                    return Array.Empty<string>();
                }
            }

            return value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        }
    }
}
