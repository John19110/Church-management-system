using System.ComponentModel.DataAnnotations;

namespace Church.BLL.DTOS.AccountDtos
{
    public sealed class CreateAccountDeletionRequestDto
    {
        /// <summary>
        /// Email address that will receive the ownership-verification link.
        /// When the account has an Identity email, it must match this address.
        /// </summary>
        [Required]
        [EmailAddress]
        [MaxLength(256)]
        public string Email { get; set; } = default!;

        /// <summary>
        /// Optional phone number used to sign in. Helps locate accounts that have no
        /// Identity email. Ignored when <see cref="Email"/> already matches a user.
        /// </summary>
        [MaxLength(32)]
        public string? PhoneNumber { get; set; }

        /// <summary>
        /// Optional church or meeting name provided by the requester for support context.
        /// Not used to authorize deletion.
        /// </summary>
        [MaxLength(200)]
        public string? ChurchOrMeetingName { get; set; }
    }

    public sealed class ConfirmAccountDeletionRequestDto
    {
        [Required]
        [MaxLength(200)]
        public string Token { get; set; } = default!;
    }

    public sealed class AccountDeletionRequestResponseDto
    {
        public string Message { get; set; } = default!;
    }
}
