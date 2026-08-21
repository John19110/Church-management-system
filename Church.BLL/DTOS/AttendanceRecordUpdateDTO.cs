using Church.DAL.Models;
using Church.BLL.DTOS.AttendanceCriteria;
using System.Collections.Generic;

namespace Church.BLL.DTOS
{
    public class AttendanceRecordUpdateDTO
    {
        public int Id { get; set; }
        public int MemberId { get; set; }

        public bool MadeHomeWork { get; set; } = false;
        public bool HasTools { get; set; } = false;

        public AttendanceStatus Status { get; set; } = AttendanceStatus.Present;
        public string? Note { get; set; }

        public List<AttendanceCriterionResultAddDTO> CriterionResults { get; set; } = new();
    }
}
