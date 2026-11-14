using System.Net;
using System.Net.Mail;
using Church.BLL.Services.Email;
using Microsoft.Extensions.Options;

namespace Church.API.Infrastructure.Email
{
    /// <summary>
    /// SMTP-backed email sender. When <see cref="SmtpEmailOptions"/> is not configured,
    /// messages are logged and not transmitted so local/dev hosts stay usable.
    /// </summary>
    public sealed class SmtpEmailSender : IEmailSender
    {
        private readonly SmtpEmailOptions _options;
        private readonly ILogger<SmtpEmailSender> _logger;

        public SmtpEmailSender(
            IOptions<SmtpEmailOptions> options,
            ILogger<SmtpEmailSender> logger)
        {
            _options = options.Value;
            _logger = logger;
        }

        public async Task SendAsync(
            string toAddress,
            string subject,
            string plainTextBody,
            string? htmlBody = null,
            CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(toAddress))
                throw new ArgumentException("Recipient address is required.", nameof(toAddress));

            if (!_options.IsConfigured)
            {
                _logger.LogWarning(
                    "SMTP is not configured; email was not sent. To={To} Subject={Subject}",
                    toAddress,
                    subject);
                _logger.LogInformation(
                    "Email body (SMTP disabled): {Body}",
                    plainTextBody);
                return;
            }

            using var message = new MailMessage
            {
                From = new MailAddress(
                    _options.FromAddress!,
                    _options.FromDisplayName),
                Subject = subject,
                Body = string.IsNullOrWhiteSpace(htmlBody) ? plainTextBody : htmlBody,
                IsBodyHtml = !string.IsNullOrWhiteSpace(htmlBody)
            };
            message.To.Add(toAddress);
            if (!string.IsNullOrWhiteSpace(htmlBody))
            {
                message.AlternateViews.Add(
                    AlternateView.CreateAlternateViewFromString(
                        plainTextBody,
                        null,
                        "text/plain"));
            }

            using var client = new SmtpClient(_options.Host!, _options.Port)
            {
                EnableSsl = _options.EnableSsl,
                DeliveryMethod = SmtpDeliveryMethod.Network
            };

            if (!string.IsNullOrWhiteSpace(_options.UserName))
            {
                client.Credentials = new NetworkCredential(
                    _options.UserName,
                    _options.Password);
            }

            await client.SendMailAsync(message, cancellationToken);
            _logger.LogInformation(
                "Email sent. To={To} Subject={Subject}",
                toAddress,
                subject);
        }
    }
}