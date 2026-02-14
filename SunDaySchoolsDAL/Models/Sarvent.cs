using SunDaySchoolsDAL.Models;

namespace SunDaySchools.Models
{
    public class Servant
    {
        public int Id { get; set; }
        public string ApplicationUserId { get; set; } = default!;
        public ApplicationUser ApplicationUser { get; set; } = default!;

        public string? ImageFileName { get; set; }   // e.g. "c3c2... .jpg"
        public string? ImageUrl { get; set; }
        public string? Name { get; set; }
        public DateOnly? BirthDate { get; set; }
        public string? password { get; set; }

        public DateOnly? JoiningDate { get; set; }
        public string? PhoneNumber { get; set; }
        public int? ClassroomId { get; set; }
        public Classroom? Classroom { get; set; }


    }
}
