using Microsoft.AspNetCore.Http;
using SunDaySchools.BLL.DTOS;

namespace SunDaySchools.API.Requests
{
    public class ChildAddFormRequest
    {
        public string? Name1 { get; set; }
        public string? Name2 { get; set; }
        public string? Name3 { get; set; }
        public string? Gender { get; set; }
        public string? Address { get; set; }
        public DateOnly DateOfBirth { get; set; }
        public DateOnly JoiningDate { get; set; }
        public DateOnly? SpiritualDateOfBirth { get; set; }

        public List<string>? Notes { get; set; }
        public List<string>? BrothersNames { get; set; }
        public bool? HaveBrothers { get; set; }

        public int? ClassroomId { get; set; }
        public List<ChildContactDto>? PhoneNumbers { get; set; }

        // The uploaded file
        // this field is the reason why we made this entire class 
        public IFormFile? Image { get; set; }
    }
}
