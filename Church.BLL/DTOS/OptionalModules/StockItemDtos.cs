namespace Church.BLL.DTOS.OptionalModules
{
    public sealed class StockItemReadDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? NameAr { get; set; }
        public string? Description { get; set; }
        public string? DescriptionAr { get; set; }
        public int Amount { get; set; }
        public string? ImageUrl { get; set; }
        public DateTime CreatedAtUtc { get; set; }
        public DateTime? UpdatedAtUtc { get; set; }
    }

    public sealed class StockItemCreateDto
    {
        public string Name { get; set; } = string.Empty;
        public string? NameAr { get; set; }
        public string? Description { get; set; }
        public string? DescriptionAr { get; set; }
        public int Amount { get; set; }
    }

    public sealed class StockItemUpdateDto
    {
        public string Name { get; set; } = string.Empty;
        public string? NameAr { get; set; }
        public string? Description { get; set; }
        public string? DescriptionAr { get; set; }
        public int Amount { get; set; }
    }

    public sealed class StockAmountChangeResultDto
    {
        public int Id { get; set; }
        public int Amount { get; set; }
    }
}
