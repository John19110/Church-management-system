using Microsoft.AspNetCore.Http;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
namespace SunDaySchools.BLL.DTOS
{
    public class ChildAddDTO
    {

        public string? Name1 { get; set; }
        public string? Name2 { get; set; }
        public string? Name3 { get; set; }
        public string? Gender { get; set; }
        public string? ImageFileName { get; set; }   // e.g. "c3c2... .jpg"
        public string? ImageUrl { get; set; }

        public string? Address { get; set; }
        public DateOnly DateOfBirth { get; set; }
        public DateOnly JoiningDate { get; set; }
        public DateOnly? SpiritualDateOfBirth { get; set; }
        public List<string>? Notes { get; set; }
        public List<string>?  BrothersNames { get; set; }
        public bool? HaveBrothers { get; set; }
        public int? ClassroomId { get; set; }              // ✅ ID only
        public List<ChildContactDto>? PhoneNumbers { get; set; } // ✅ DTO not entity

    }
}
