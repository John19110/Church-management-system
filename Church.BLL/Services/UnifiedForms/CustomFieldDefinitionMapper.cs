using Church.BLL.DTOS.UnifiedForms;
using Church.DAL.Models.CustomFields;

namespace Church.BLL.Services.UnifiedForms
{
    public static class CustomFieldDefinitionMapper
    {
        public static UnifiedFieldDefinitionDto ToUnifiedField(CustomFieldDefinition def)
        {
            var template = EntityDefaultFieldTemplates.FindTemplate(def.EntityName, def.Name);
            return new UnifiedFieldDefinitionDto
            {
                FieldKey = def.Name,
                DisplayName = def.DisplayName,
                DisplayNameAr = def.DisplayNameAr,
                Description = def.Description,
                DataType = def.DataType,
                IsRequired = def.IsRequired,
                IsBuiltIn = template != null,
                IsReadOnly = def.IsReadOnly,
                IsHidden = def.IsHidden,
                SortOrder = def.SortOrder,
                AllowMultipleValues = def.AllowMultipleValues,
                DefaultValue = def.DefaultValue,
                Placeholder = def.Placeholder,
                ValidationRegex = def.ValidationRegex,
                LookupEndpoint = template?.LookupEndpoint,
                CustomFieldDefinitionId = def.Id,
                Options = def.Options
                    .OrderBy(o => o.SortOrder)
                    .Select(o => new UnifiedFieldOptionDto
                    {
                        Value = o.Value,
                        DisplayText = o.DisplayText,
                        SortOrder = o.SortOrder,
                    })
                    .ToList(),
            };
        }
    }
}
