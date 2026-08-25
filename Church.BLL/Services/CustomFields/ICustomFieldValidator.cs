using Church.DAL.Models.CustomFields;

namespace Church.BLL.Services.CustomFields
{
    public interface ICustomFieldValidator
    {
        bool TryValidateValue(
            CustomFieldDefinition definition,
            string? rawValue,
            out string? normalizedValue,
            out string errorMessage);

        bool CanParseAsType(
            CustomFieldDataType dataType,
            string? rawValue,
            IReadOnlySet<string>? allowedOptionValues);

        IReadOnlySet<string> GetAllowedOptionValues(CustomFieldDefinition definition);
    }
}
