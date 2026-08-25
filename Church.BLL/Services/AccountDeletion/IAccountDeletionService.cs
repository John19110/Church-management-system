namespace Church.BLL.Services.AccountDeletion
{
    /// <summary>
    /// Permanently deletes the currently authenticated account and its personal data.
    /// </summary>
    public interface IAccountDeletionService
    {
        /// <summary>
        /// Deletes the current account in a database transaction and removes profile images.
        /// </summary>
        Task DeleteCurrentAccountAsync(
            string webRootPath,
            CancellationToken cancellationToken = default);
    }
}
