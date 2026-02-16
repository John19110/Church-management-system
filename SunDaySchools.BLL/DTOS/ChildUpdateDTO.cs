using Microsoft.AspNetCore.Http;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;

namespace SunDaySchools.BLL.DTOS
{
    public class ChildUpdateDTO
    {
        public int Id { get; set; }
        public string? Name1 { get; set; }
        public string? Name2 { get; set; }
        public string? Name3 { get; set; }
        public string? Gender { get; set; }
        public string? Address { get; set; }
        public DateOnly DateOfBirth { get; set; }
        public DateOnly JoiningDate { get; set; }
        public DateOnly LastAttendanceDate { get; set; }
        public DateOnly? SpiritualDateOfBirth { get; set; }
        public bool? IsDisciplineChild { get; set; }
        public int? TotalNumberOfDaysAttended { get; set; } = 0;


        public List<ChildContactDTO>? PhoneNumbers { get; set; }

        public bool? HaveBrothers { get; set; }
        public List<string>? BrothersNames { get; set; }

        public int? ClassroomId { get; set; }

        public List<string>? Notes { get; set; }
    }
}
