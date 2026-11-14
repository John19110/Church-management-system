namespace Church.BLL.Services.Email
{
    public interface IEmailSender
    {
        /// <summary>
        /// Sends a plain-text (and optional HTML) email. Implementations may no-op when
        /// SMTP is not configured; callers must not treat a completed task as proof of delivery.
        /// </summary>
        Task SendAsync(
            string toAddress,
            string subject,
            string plainTextBody,
            string? htmlBody = null,
            CancellationToken cancellationToken = default);
    }
}
