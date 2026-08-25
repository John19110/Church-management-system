using Church.DAL.Models.CustomFields;

namespace Church.BLL.Services.UnifiedForms
{
    internal static class FormCustomValuesLookup
    {
        public static IReadOnlyDictionary<int, string?> FromValues(
            IEnumerable<CustomFieldValue> values)
        {
            return values
                .GroupBy(v => v.CustomFieldDefinitionId)
                .ToDictionary(g => g.Key, g => g.Last().Value);
        }
    }
}
