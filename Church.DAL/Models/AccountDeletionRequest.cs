namespace Church.DAL.Models
{
    /// <summary>
    /// Tracks a public web request to delete an Identity account after email verification.
    /// </summary>
    public class AccountDeletionRequest
    {
        public Guid Id { get; set; }

        /// <summary>Identity user targeted for deletion once the request is verified.</summary>
        public string UserId { get; set; } = default!;

        public ApplicationUser? User { get; set; }

        /// <summary>Email address that must confirm ownership before deletion proceeds.</summary>
        public string Email { get; set; } = default!;

        /// <summary>SHA-256 hash of the raw confirmation token (raw token is emailed once).</summary>
        public string TokenHash { get; set; } = default!;

        public AccountDeletionRequestStatus Status { get; set; }
            = AccountDeletionRequestStatus.PendingVerification;

        public DateTime CreatedAtUtc { get; set; }

        public DateTime ExpiresAtUtc { get; set; }

        public DateTime? ConfirmedAtUtc { get; set; }

        public DateTime? CompletedAtUtc { get; set; }

        /// <summary>Optional client IP captured at request time for abuse investigation.</summary>
        public string? RequestIp { get; set; }
    }

    public enum AccountDeletionRequestStatus
    {
        PendingVerification = 0,
        Completed = 1,
        Expired = 2,
        Cancelled = 3
    }
}
