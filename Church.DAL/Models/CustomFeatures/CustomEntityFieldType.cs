namespace Church.DAL.Models.CustomFeatures
{
    /// <summary>
    /// Supported custom-entity field types. Stored as string in SQL.
    /// </summary>
    public enum CustomEntityFieldType
    {
        Text = 0,
        LongText = 1,
        Number = 2,
        Decimal = 3,
        Boolean = 4,
        Date = 5,
        Time = 6,
        DateTime = 7,
        Phone = 8,
        Email = 9,
        Url = 10,
        Dropdown = 11,
        MultiSelect = 12,
        MemberReference = 13,
        ServantReference = 14,
        EntityReference = 15,
        EntityMultiReference = 16
    }
}
