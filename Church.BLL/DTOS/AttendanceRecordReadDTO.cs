using Church.DAL.Models;
using Church.BLL.DTOS.AttendanceCriteria;
using System.Collections.Generic;

namespace Church.BLL.DTOS
{
    public class AttendanceRecordReadDTO
    {
        public int Id { get; set; }
        public int ChildId { get; set; }
        public string? MemberName { get; set; }

        /// <summary>Legacy mirrors; prefer CriterionResults for UI.</summary>
        public bool MadeHomeWork { get; set; } = false;
        public bool HasTools { get; set; } = false;

        public AttendanceStatus Status { get; set; } = AttendanceStatus.Present;
        public string? Note { get; set; }

        public List<AttendanceCriterionResultReadDTO> CriterionResults { get; set; } = new();
    }
}
