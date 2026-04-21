using System.ComponentModel.DataAnnotations;

namespace SunDaySchools.API.Requests
{
    public class ServantProfileFormRequest
    {
        [StringLength(100)]
        public string? Name { get; set; }

        [Phone]
        public string? PhoneNumber { get; set; }

        public DateOnly? BirthDate { get; set; }
        public DateOnly? JoiningDate { get; set; }

        /// <summary>
        /// Optional “spiritual” date of birth. Not currently stored for servants in the DB model,
        /// but included here so the mobile UI can send it if/when supported.
        /// </summary>
        public DateOnly? SpiritualBirthDate { get; set; }

        public int? ChurchId { get; set; }
        public int? MeetingId { get; set; }

        public List<int>? ClassroomIds { get; set; }

        public IFormFile? Image { get; set; }
    }
}

