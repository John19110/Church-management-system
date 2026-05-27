namespace SunDaySchools.DAL.Models.CustomFields
{
    /// <summary>
    /// Entity names that custom fields can attach to. Must match API/Flutter contracts.
    /// </summary>
    public static class CustomFieldEntityNames
    {
        public const string Member = "Member";
        public const string Classroom = "Classroom";
        public const string Servant = "Servant";
        public const string Meeting = "Meeting";
        public const string Church = "Church";

        public static readonly IReadOnlySet<string> All = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            Member, Classroom, Servant, Meeting, Church
        };

        public static bool IsSupported(string entityName) =>
            !string.IsNullOrWhiteSpace(entityName) && All.Contains(entityName);
    }
}
