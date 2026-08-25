using Church.BLL.DTOS.CustomFields;
using Church.DAL.Models.CustomFields;

namespace Church.BLL.Services.UnifiedForms
{
    /// <summary>
    /// Built-in model properties provisioned as <see cref="CustomFieldDefinition"/> rows.
    /// Navigation collections and computed-only properties are excluded.
    /// </summary>
    public static class EntityDefaultFieldTemplates
    {
        public sealed record Template(
            string Name,
            string DisplayName,
            CustomFieldDataType DataType,
            int SortOrder,
            bool IsRequired = false,
            bool IsReadOnly = false,
            bool IsHidden = false,
            bool HideInCreate = false,
            bool IsCritical = false,
            string? LookupEndpoint = null,
            string? Placeholder = null,
            string? ValidationRegex = null);

        private static readonly IReadOnlyDictionary<string, IReadOnlyList<Template>> Templates =
            new Dictionary<string, IReadOnlyList<Template>>(StringComparer.OrdinalIgnoreCase)
            {
                [CustomFieldEntityNames.Classroom] = new List<Template>
                {
                    new("name", "Class Name", CustomFieldDataType.Text, 10, IsRequired: true, IsCritical: true),
                    new("ageOfMembers", "Age Of Members", CustomFieldDataType.Text, 20),
                    new("numberOfDisplineMembers", "Number Of Discipline Members", CustomFieldDataType.Number, 30),
                    new("totalMembersCount", "Total Members Count", CustomFieldDataType.Number, 40, IsReadOnly: true),
                    new("leaderServantId", "Leader Servant", CustomFieldDataType.SingleSelect, 50,
                        LookupEndpoint: "/api/Servant/select"),
                    new("servantIds", "Servants", CustomFieldDataType.MultiSelect, 55,
                        LookupEndpoint: "/api/Servant/select"),
                },
                [CustomFieldEntityNames.Servant] = new List<Template>
                {
                    new("name", "Name", CustomFieldDataType.Text, 10, IsRequired: true, IsCritical: true),
                    new("phoneNumber", "Phone Number", CustomFieldDataType.Text, 20),
                    new("birthDate", "Birth Date", CustomFieldDataType.Date, 30),
                    new("joiningDate", "Joining Date", CustomFieldDataType.Date, 40),
                    new("classroomId", "Classroom", CustomFieldDataType.SingleSelect, 50,
                        LookupEndpoint: "/api/Classroom/select"),
                    new("imageUrl", "Photo", CustomFieldDataType.Text, 60, IsHidden: true, HideInCreate: true),
                },
                [CustomFieldEntityNames.Member] = new List<Template>
                {
                    new("name1", "First Name", CustomFieldDataType.Text, 10, IsRequired: true, IsCritical: true),
                    new("name2", "Middle Name", CustomFieldDataType.Text, 20),
                    new("name3", "Last Name", CustomFieldDataType.Text, 30),
                    new("gender", "Gender", CustomFieldDataType.Text, 40),
                    new("address", "Address", CustomFieldDataType.LongText, 50),
                    new("dateOfBirth", "Date Of Birth", CustomFieldDataType.Date, 60, IsRequired: true),
                    new("joiningDate", "Joining Date", CustomFieldDataType.Date, 70, IsRequired: true),
                    new("spiritualDateOfBirth", "Spiritual Date Of Birth", CustomFieldDataType.Date, 80),
                    new("lastAttendanceDate", "Last Attendance Date", CustomFieldDataType.Date, 90, IsReadOnly: true),
                    new("isDiscipline", "Discipline", CustomFieldDataType.Boolean, 100),
                    new("totalNumberOfDaysAttended", "Total Days Attended", CustomFieldDataType.Number, 110, IsReadOnly: true),
                    new("haveBrothers", "Have Brothers In Program", CustomFieldDataType.Boolean, 120),
                    new("brothersNames", "Brothers Names", CustomFieldDataType.Json, 130),
                    new("notes", "Notes", CustomFieldDataType.Json, 140),
                    new("phoneNumbers", "Phone Numbers", CustomFieldDataType.Json, 150),
                    new("classroomId", "Classroom", CustomFieldDataType.SingleSelect, 160,
                        LookupEndpoint: "/api/Classroom/select"),
                    new("imageUrl", "Photo", CustomFieldDataType.Text, 170, IsHidden: true, HideInCreate: true),
                },
                [CustomFieldEntityNames.Meeting] = new List<Template>
                {
                    new("name", "Meeting Name", CustomFieldDataType.Text, 10, IsRequired: true, IsCritical: true),
                    new("dayOfWeek", "Day Of Week", CustomFieldDataType.Text, 20),
                    new("weeklyAppointment", "Weekly Appointment", CustomFieldDataType.Text, 30),
                    new("leaderServantId", "Leader Servant", CustomFieldDataType.SingleSelect, 40,
                        LookupEndpoint: "/api/Servant/select"),
                },
                [CustomFieldEntityNames.Church] = new List<Template>
                {
                    new("name", "Church Name", CustomFieldDataType.Text, 10, IsRequired: true, IsCritical: true),
                    new("pastorId", "Pastor", CustomFieldDataType.SingleSelect, 20,
                        LookupEndpoint: "/api/Servant/select"),
                },
            };

        public static IReadOnlyList<Template> GetTemplates(string entityName) =>
            Templates.TryGetValue(entityName, out var list)
                ? list
                : Array.Empty<Template>();

        public static Template? FindTemplate(string entityName, string fieldName) =>
            GetTemplates(entityName)
                .FirstOrDefault(t => t.Name.Equals(fieldName, StringComparison.OrdinalIgnoreCase));

        public static bool IsBuiltInField(string entityName, string fieldName) =>
            FindTemplate(entityName, fieldName) != null;

        public static bool IsCriticalField(string entityName, string fieldName) =>
            FindTemplate(entityName, fieldName)?.IsCritical == true;

        public static bool ShouldIncludeInMode(Template template, EntityFormMode mode) =>
            mode != EntityFormMode.Create || !template.HideInCreate;

        /// <summary>
        /// Ensures all built-in templates appear in admin API responses even when DB rows
        /// are missing or filtered by tenant scope.
        /// </summary>
        public static List<CustomFieldDefinitionReadDto> MergeDefinitionDtos(
            string entityName,
            IReadOnlyList<CustomFieldDefinitionReadDto> fromDb,
            IReadOnlySet<string>? permanentlyDeletedNames = null)
        {
            var byName = fromDb.ToDictionary(d => d.Name, StringComparer.OrdinalIgnoreCase);
            var merged = new List<CustomFieldDefinitionReadDto>();

            foreach (var template in GetTemplates(entityName))
            {
                if (permanentlyDeletedNames?.Contains(template.Name) == true)
                    continue;

                if (byName.TryGetValue(template.Name, out var existing))
                {
                    merged.Add(existing);
                    byName.Remove(template.Name);
                }
                else
                {
                    merged.Add(TemplateToReadDto(entityName, template));
                }
            }

            merged.AddRange(byName.Values.Where(d => !IsBuiltInField(entityName, d.Name)));

            return merged
                .OrderBy(d => d.SortOrder)
                .ThenBy(d => d.DisplayName, StringComparer.OrdinalIgnoreCase)
                .ToList();
        }

        public static CustomFieldDefinitionReadDto TemplateToReadDto(
            string entityName,
            Template template) =>
            new()
            {
                Id = 0,
                Name = template.Name,
                DisplayName = template.DisplayName,
                EntityName = entityName,
                DataType = template.DataType,
                IsRequired = template.IsRequired,
                IsActive = true,
                IsReadOnly = template.IsReadOnly,
                IsHidden = template.IsHidden,
                SortOrder = template.SortOrder,
                Placeholder = template.Placeholder,
                ValidationRegex = template.ValidationRegex,
                IsBuiltIn = true,
                IsSystemField = true,
                IsDeletable = !template.IsCritical,
                IsPermanentDeletable = !template.IsCritical,
                CreatedAt = DateTime.UtcNow,
            };
    }
}
