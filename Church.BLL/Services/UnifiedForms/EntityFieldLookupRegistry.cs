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
                (CustomFieldEntityNames.Member, "classroomid") => "/api/classrooms/select",
                (CustomFieldEntityNames.Classroom, "leaderservantid") => "/api/servants/select",
                (CustomFieldEntityNames.Servant, "classroomid") => "/api/classrooms/select",
                (CustomFieldEntityNames.Meeting, "leaderservantid") => "/api/servants/select",
                (CustomFieldEntityNames.Church, "pastorid") => "/api/servants/select",
                _ => null
            };
    }
}
