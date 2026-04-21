namespace SunDaySchools.BLL.DTOS
{
    public class AttendanceSessionSummaryDTO
    {
        public int Id { get; set; }
        public DateOnly CreatedAt { get; set; }
        public string? Notes { get; set; }
        public int RecordsCount { get; set; }
    }
}

