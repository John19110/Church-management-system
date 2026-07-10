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
    }
}
