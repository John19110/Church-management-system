using Church.DAL.Models.CustomFields;

namespace Church.BLL.Services.UnifiedForms
{
    /// <summary>
    /// Maps unified field keys to legacy SQL columns when saving entity forms.
    /// </summary>
    public static class EntityColumnSyncRegistry
    {
        private static readonly IReadOnlyDictionary<string, IReadOnlySet<string>> SyncKeys =
            new Dictionary<string, IReadOnlySet<string>>(StringComparer.OrdinalIgnoreCase)
            {
                [CustomFieldEntityNames.Member] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
                {
                    "name1", "name2", "name3", "gender", "address", "dateOfBirth", "joiningDate",
                    "spiritualDateOfBirth", "lastAttendanceDate", "isDiscipline",
                    "totalNumberOfDaysAttended", "haveBrothers", "brothersNames", "notes",
                    "phoneNumbers", "classroomId",
                },
                [CustomFieldEntityNames.Classroom] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
                {
                    "name", "ageOfMembers", "leaderServantId", "servantIds",
                },
                [CustomFieldEntityNames.Servant] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
                {
                    "name", "phoneNumber", "birthDate", "joiningDate", "classroomId", "imageUrl",
                },
                [CustomFieldEntityNames.Meeting] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
                {
                    "name", "dayOfWeek", "weeklyAppointment", "leaderServantId",
                },
                [CustomFieldEntityNames.Church] = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
                {
                    "name", "pastorId",
                },
            };

        public static bool CanSyncToEntityTable(string entityName, string fieldKey) =>
            SyncKeys.TryGetValue(entityName, out var keys) && keys.Contains(fieldKey);

        public static IReadOnlyList<string> GetRecommendedFieldKeys(string entityName) =>
            SyncKeys.TryGetValue(entityName, out var keys)
                ? keys.OrderBy(k => k, StringComparer.OrdinalIgnoreCase).ToList()
                : Array.Empty<string>();
    }
}
