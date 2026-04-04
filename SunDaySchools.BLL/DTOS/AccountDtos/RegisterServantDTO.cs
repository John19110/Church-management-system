using Microsoft.AspNetCore.Http;

namespace SunDaySchools.BLL.DTOS.AccountDtos
{
    public class RegisterServantDTO
    {
        public string Name { get; set; }

        public string PhoneNumber { get; set; }

        public string Password { get; set; }


        public IFormFile? Image { get; set; }   // ✅ correct way

        public string ConfirmPassword { get; set; }

        public int ChurchId { get; set; }

        public int MeetingId { get; set; }


        public DateOnly? BirthDate { get; set; }
        public DateOnly? JoiningDate { get; set; }
        public List<int>? classroomsIds { get; set; }
    }
}