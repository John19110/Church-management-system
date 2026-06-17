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

        public string ChurchPublicId { get; set; } = string.Empty;

        /// <summary>
        /// Legacy field: public meeting identifier. No longer required for public
        /// servant registration — the meeting is assigned by the Super Admin on approval.
        /// </summary>
        public string MeetingPublicId { get; set; } = string.Empty;

        /// <summary>Free-text meeting/class name the user wants to join (e.g. "Preparatory Boys").</summary>
        public string RequestedMeetingName { get; set; } = string.Empty;

        /// <summary>Requested role for existing-church registration: Servant / MeetingAdmin / ChurchAdmin.</summary>
        public string RequestedRole { get; set; } = "Servant";

        /// <summary>Phone of the Meeting Admin responsible for the requested meeting (required for Servant).</summary>
        public string? MeetingAdminPhoneNumber { get; set; }


        public DateOnly? BirthDate { get; set; }
        public DateOnly? JoiningDate { get; set; }
       // public List<int>? classroomsIds { get; set; }
    }
}