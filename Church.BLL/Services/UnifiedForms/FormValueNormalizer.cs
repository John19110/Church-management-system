namespace Church.BLL.Services.UnifiedForms
{
    internal static class FormValueNormalizer
    {
        public static IReadOnlyDictionary<string, string?> BuildSubmittedMap(
            IEnumerable<(string FieldKey, string? Value)> fields)
        {
            return fields
                .Where(f => !string.IsNullOrWhiteSpace(f.FieldKey))
                .GroupBy(f => f.FieldKey, StringComparer.OrdinalIgnoreCase)
                .ToDictionary(
                    g => g.Key,
                    g => g.Last().Value,
                    StringComparer.OrdinalIgnoreCase);
        }
    }
}
