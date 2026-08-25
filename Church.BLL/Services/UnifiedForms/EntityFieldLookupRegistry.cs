using Church.DAL.Models.CustomFields;

namespace Church.BLL.Services.UnifiedForms
{
    /// <summary>
    /// API lookup routes for select-style default fields (not stored on <see cref="CustomFieldDefinition"/>).
    /// </summary>
    public static class EntityFieldLookupRegistry
    {
        public static string? GetLookupEndpoint(string entityName, string fieldKey) =>
            (entityName, fieldKey.ToLowerInvariant()) switch
            {
                (CustomFieldEntityNames.Member, "classroomid") => "/api/Classroom/select",
                (CustomFieldEntityNames.Classroom, "leaderservantid") => "/api/Servant/select",
                (CustomFieldEntityNames.Servant, "classroomid") => "/api/Classroom/select",
                (CustomFieldEntityNames.Meeting, "leaderservantid") => "/api/Servant/select",
                (CustomFieldEntityNames.Church, "pastorid") => "/api/Servant/select",
                _ => null
            };
    }
}
