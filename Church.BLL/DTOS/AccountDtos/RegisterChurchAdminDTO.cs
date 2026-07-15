using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace Church.BLL.DTOS.AccountDtos
{
    public class RegisterChurchAdminDTO
    {
        [Required(ErrorMessage = "Name is required.")]
        public string Name { get; set; } = string.Empty;

        public IFormFile? Image { get; set; }

        [Required(ErrorMessage = "Phone number is required.")]
        public string PhoneNumber { get; set; } = string.Empty;

        [Required(ErrorMessage = "Password is required.")]
        [MinLength(6, ErrorMessage = "Password must contain at least 6 characters.")]
        public string Password { get; set; } = string.Empty;

        [Required(ErrorMessage = "Confirm password is required.")]
        [Compare(nameof(Password), ErrorMessage = "Password and confirm password do not match.")]
        public string ConfirmPassword { get; set; } = string.Empty;

        [Required(ErrorMessage = "Church name is required.")]
        public string ChurchName { get; set; } = string.Empty;

        public DateOnly? BirthDate { get; set; }
        public DateOnly? JoiningDate { get; set; }
    }
}
