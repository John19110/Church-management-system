namespace Church.BLL.DTOS.ChurchDtos
{
    public class ChurchReadDTO
    {
        public int Id { get; set; }
        public string PublicId { get; set; } = string.Empty;
        public string? Name { get; set; }
        public int? PastorId { get; set; }
        public string? PastorName { get; set; }
    }
}

