using Church.DAL.Models;
using Church.BLL.DTOS.AttendanceCriteria;

namespace Church.BLL.DTOS
{
    public class AttendanceRecordAddDTO
    {
        public int MemberId { get; set; }

        /// <summary>Legacy; dual-written when criterionResults omit has_tools / did_homework.</summary>
        public bool MadeHomeWork { get; set; } = false;
        public bool HasTools { get; set; } = false;

        public AttendanceStatus Status { get; set; } = AttendanceStatus.Present;
        public string? Note { get; set; }

        public List<AttendanceCriterionResultAddDTO> CriterionResults { get; set; } = new();
    }
}
