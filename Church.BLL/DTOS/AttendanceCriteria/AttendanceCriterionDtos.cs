using Church.DAL.Models;
using System.ComponentModel.DataAnnotations;

namespace Church.BLL.DTOS.AttendanceCriteria
{
    public class AttendanceCriterionReadDTO
    {
        public int Id { get; set; }
        public int MeetingId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
        public AttendanceCriterionDataType DataType { get; set; }
        public bool IsActive { get; set; }
        public int SortOrder { get; set; }
    }

    public class AttendanceCriterionAddDTO
    {
        [Required]
        [MaxLength(200)]
        public string DisplayName { get; set; } = string.Empty;

        [MaxLength(200)]
        public string? DisplayNameAr { get; set; }

        /// <summary>Optional stable key; generated from display name when omitted.</summary>
        [MaxLength(100)]
        public string? Name { get; set; }

        public int? SortOrder { get; set; }
    }

    public class AttendanceCriterionUpdateDTO
    {
        [Required]
        [MaxLength(200)]
        public string DisplayName { get; set; } = string.Empty;

        [MaxLength(200)]
        public string? DisplayNameAr { get; set; }

        public bool IsActive { get; set; } = true;

        public int SortOrder { get; set; }
    }

    public class AttendanceCriterionReorderDTO
    {
        [Required]
        public List<int> OrderedIds { get; set; } = new();
    }

    public class AttendanceCriterionResultAddDTO
    {
        public int CriterionId { get; set; }
        public bool Value { get; set; }
    }

    public class AttendanceCriterionResultReadDTO
    {
        public int CriterionId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
        public bool? Value { get; set; }
    }
}
