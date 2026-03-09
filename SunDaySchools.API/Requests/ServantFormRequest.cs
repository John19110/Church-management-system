using System.ComponentModel.DataAnnotations;

namespace SunDaySchools.API.Requests
{
    public class ServantFormRequest
    {
        [StringLength(100)]
        public string? Name { get; set; }

        public DateOnly? JoiningDate { get; set; }
        public DateOnly? BirthDate { get; set; }

        [Phone]
        public string? PhoneNumber { get; set; }

        [Required]
        public string ApplicationUserId { get; set; } = default!;

        public int? ClassroomId { get; set; }

        public IFormFile? Image { get; set; }
    }
}