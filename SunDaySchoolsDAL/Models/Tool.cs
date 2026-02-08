namespace SunDaySchools.Models
{
    public class Tool
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? Kind { get; set; }  
        public string? Description { get; set; }
        public string? Place { get; set; }
        public int? Quantity { get; set; }
        public bool? IsAvailable { get; set; } = true;
        public DateOnly? DateOfLastUse { get; set; }
        public string? Notes { get; set; }
    }

}
