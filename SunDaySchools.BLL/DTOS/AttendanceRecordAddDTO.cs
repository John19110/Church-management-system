using SunDaySchools.DAL.Models;

namespace SunDaySchools.BLL.DTOS
{
    public class AttendanceRecordAddDTO
    {
        public int ChildId { get; set; }

        public bool MadeHomeWork { get; set; } = false;
        public bool HasTools { get; set; } = false;

        public AttendanceStatus Status { get; set; } = AttendanceStatus.Present;
        public string? Note { get; set; }
    }
}