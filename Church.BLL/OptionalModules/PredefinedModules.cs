namespace Church.BLL.OptionalModules
{
    /// <summary>
    /// Developer-maintained catalog of optional modules. Add new modules here only.
    /// </summary>
    public static class PredefinedModules
    {
        public const string Stock = "stock";

        public static readonly IReadOnlyList<PredefinedModuleDefinition> All =
            new[]
            {
                new PredefinedModuleDefinition(
                    Id: Stock,
                    NameEn: "Stock",
                    NameAr: "المخزن",
                    DescriptionEn: "Track items available in your organization's stock, including quantities and images.",
                    DescriptionAr: "تتبع الأصناف المتوفرة في مخزن مؤسستك، بما في ذلك الكميات والصور.",
                    Icon: "inventory_2")
            };

        private static readonly Dictionary<string, PredefinedModuleDefinition> ById =
            All.ToDictionary(m => m.Id, StringComparer.OrdinalIgnoreCase);

        public static bool TryGet(string moduleId, out PredefinedModuleDefinition definition) =>
            ById.TryGetValue(moduleId?.Trim() ?? string.Empty, out definition!);

        public static bool IsKnown(string moduleId) =>
            TryGet(moduleId, out _);
    }

    public sealed record PredefinedModuleDefinition(
        string Id,
        string NameEn,
        string NameAr,
        string DescriptionEn,
        string DescriptionAr,
        string Icon);
}
