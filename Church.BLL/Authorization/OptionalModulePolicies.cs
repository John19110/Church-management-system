namespace Church.BLL.Authorization
{
    public static class OptionalModulePolicies
    {
        public const string ManageActivation = "OptionalModules.ManageActivation";
        public const string UseStock = "OptionalModules.UseStock";
    }

    public static class OptionalModuleRoles
    {
        public const string SuperAdmin = "SuperAdmin";
        public const string Admin = "Admin";
        public const string Servant = "Servant";

        public static readonly string[] ActivationManagers = { SuperAdmin, Admin };
        public static readonly string[] StockUsers = { SuperAdmin, Admin, Servant };
    }
}
