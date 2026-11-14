using Church.BLL.DTOS.AccountDtos;

namespace Church.BLL.Services.AccountDeletion
{
    /// <summary>
    /// Permanently deletes Identity accounts and personal data, including the public
    /// email-verified deletion request flow required for store compliance pages.
    /// </summary>
    public interface IAccountDeletionService
    {
        /// <summary>
        /// Deletes the current authenticated account in a database transaction and
        /// removes profile images.
        /// </summary>
        Task DeleteCurrentAccountAsync(
            string webRootPath,
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Creates a tracked deletion request and emails an expiring confirmation token.
        /// Always returns a generic success message so callers cannot enumerate accounts.
        /// Never deletes an account from this call alone.
        /// </summary>
        Task<AccountDeletionRequestResponseDto> RequestDeletionAsync(
            CreateAccountDeletionRequestDto dto,
            string? requestIp,
            CancellationToken cancellationToken = default);

        /// <summary>
        /// Verifies an emailed token and, only when valid and unexpired, permanently
        /// deletes the linked account.
        /// </summary>
        Task ConfirmDeletionAsync(
            ConfirmAccountDeletionRequestDto dto,
            string webRootPath,
            CancellationToken cancellationToken = default);
    }
}
