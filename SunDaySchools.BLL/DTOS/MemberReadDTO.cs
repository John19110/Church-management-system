using SunDaySchools.DAL.Models;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.DTOS
{
    public class MemberReadDTO
    {
        public string? FullName { get; set; }
        public string? ImageFileName { get; set; }
        public string? ImageUrl { get; set; }
        public string? Address { get; set; }
        public string? Gender { get; set; }
        public DateOnly DateOfBirth { get; set; }
        public DateOnly JoiningDate { get; set; }
        public DateOnly LastAttendanceDate { get; set; }
        public DateOnly? SpiritualDateOfBirth { get; set; }
        public bool? IsDiscipline { get; set; }
        public int? TotalNumberOfDaysAttended { get; set; }
        public List<MemberContactDTO>? PhoneNumbers { get; set; }   
        public bool? HaveBrothers { get; set; }
        public List<string>? BrothersNames { get; set; }
        public int?  ClassroomId { get; set; }
        public List<string>? Notes { get; set; }
        public List<AttendanceRecordReadDTO> AttendanceHistory { get; set; } = new();

    }
}
