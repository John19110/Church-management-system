namespace SunDaySchools.DAL.Models.CustomFields
{
    /// <summary>
    /// Supported dynamic field types. Stored as string in SQL for stable schema evolution.
    /// API serializes as string names (e.g. "LongText") via JsonStringEnumConverter in the API host.
    /// </summary>
    public enum CustomFieldDataType
    {
        Text = 0,
        LongText = 1,
        Number = 2,
        Decimal = 3,
        Boolean = 4,
        Date = 5,
        DateTime = 6,
        Json = 7,
        SingleSelect = 8,
        MultiSelect = 9
    }
}
