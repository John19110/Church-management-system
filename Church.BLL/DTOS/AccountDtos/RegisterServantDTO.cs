using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace Church.BLL.DTOS.AccountDtos
{
    public class RegisterServantDTO
    {
        [Required(ErrorMessage = "Name is required.")]
        public string Name { get; set; } = string.Empty;

        [Required(ErrorMessage = "Phone number is required.")]
        public string PhoneNumber { get; set; } = string.Empty;

        [Required(ErrorMessage = "Password is required.")]
        [MinLength(6, ErrorMessage = "Password must contain at least 6 characters.")]
        public string Password { get; set; } = string.Empty;

        public IFormFile? Image { get; set; }

        [Required(ErrorMessage = "Confirm password is required.")]
        [Compare(nameof(Password), ErrorMessage = "Password and confirm password do not match.")]
        public string ConfirmPassword { get; set; } = string.Empty;

        /// <summary>Public Church ID or public Meeting ID entered at registration.</summary>
        [Required(ErrorMessage = "A valid church or meeting identifier is required.")]
        public string ChurchPublicId { get; set; } = string.Empty;

        /// <summary>Free-text meeting/class name the user wants to join (e.g. "Preparatory Boys").</summary>
        public string RequestedMeetingName { get; set; } = string.Empty;

        /// <summary>Requested role for existing-church registration: Servant / MeetingAdmin / ChurchAdmin.</summary>
        public string RequestedRole { get; set; } = "Servant";

        /// <summary>Phone of the Meeting Admin responsible for the requested meeting (required for Servant).</summary>
        public string? MeetingAdminPhoneNumber { get; set; }

        public DateOnly? BirthDate { get; set; }
        public DateOnly? JoiningDate { get; set; }
    }
}
