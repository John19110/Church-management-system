namespace Church.BLL.Authorization
{
    public static class CustomFieldPolicies
    {
        public const string ManageDefinitions = "CustomFields.ManageDefinitions";
        public const string ReadDefinitions = "CustomFields.ReadDefinitions";
        public const string WriteValues = "CustomFields.WriteValues";
    }

    public static class CustomFieldRoles
    {
        public const string SuperAdmin = "SuperAdmin";
        public const string Admin = "Admin";
        public const string Servant = "Servant";

        public static readonly string[] DefinitionManagers = { SuperAdmin, Admin };

        /// <summary>
        /// Roles allowed to write custom field values. Servants are included because they edit
        /// member records; the point is to exclude accounts that hold no operational role at all.
        /// </summary>
        public static readonly string[] ValueWriters = { SuperAdmin, Admin, Servant };
    }
}
