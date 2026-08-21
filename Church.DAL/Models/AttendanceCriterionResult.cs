namespace Church.DAL.Models
{
    /// <summary>
    /// Per-member result for one attendance criterion within a session record.
    /// DisplayNameSnapshot preserves the label at the time attendance was taken.
    /// </summary>
    public class AttendanceCriterionResult
    {
        public int Id { get; set; }

        public int AttendanceRecordId { get; set; }
        public AttendanceRecord? AttendanceRecord { get; set; }

        public int AttendanceCriterionId { get; set; }
        public AttendanceCriterion? AttendanceCriterion { get; set; }

        public bool? BoolValue { get; set; }

        public string DisplayNameSnapshot { get; set; } = string.Empty;
        public string? DisplayNameArSnapshot { get; set; }
    }
}
