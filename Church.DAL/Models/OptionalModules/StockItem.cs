namespace Church.DAL.Models.OptionalModules
{
    /// <summary>
    /// Inventory row for the Stock optional module. Tenant-scoped via <see cref="ChurchEntity"/>.
    /// </summary>
    public class StockItem : ChurchEntity
    {
        public int Id { get; set; }

        public string Name { get; set; } = string.Empty;
        public string? NameAr { get; set; }

        public string? Description { get; set; }
        public string? DescriptionAr { get; set; }

        /// <summary>Current quantity on hand. Must never be negative.</summary>
        public int Amount { get; set; }

        public string? ImageFileName { get; set; }
        public string? ImageUrl { get; set; }

        public DateTime CreatedAtUtc { get; set; }
        public DateTime? UpdatedAtUtc { get; set; }
        public string? CreatedBy { get; set; }
    }
}
