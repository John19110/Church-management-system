namespace Church.BLL.Authorization
{
    public static class CustomFeaturePolicies
    {
        public const string ManageMetadata = "CustomFeatures.ManageMetadata";
        public const string UseRecords = "CustomFeatures.UseRecords";
    }

    public static class CustomFeatureRoles
    {
        public const string SuperAdmin = "SuperAdmin";
        public const string Admin = "Admin";
        public const string Servant = "Servant";

        public static readonly string[] MetadataManagers = { SuperAdmin, Admin };
        public static readonly string[] RecordUsers = { SuperAdmin, Admin, Servant };
        public static readonly string[] All = { SuperAdmin, Admin, Servant };
    }
}
