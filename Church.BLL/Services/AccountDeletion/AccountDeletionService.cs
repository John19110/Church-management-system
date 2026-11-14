using System.Security.Cryptography;
using System.Text;
using Church.BLL.Abstractions;
using Church.BLL.DTOS.AccountDtos;
using Church.BLL.Exceptions;
using Church.BLL.Services.Auth;
using Church.BLL.Services.Email;
using Church.DAL.DBcontext;
using Church.DAL.Models;
using Church.DAL.Repository.Interfaces;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Church.BLL.Services.AccountDeletion
{
    /// <summary>
    /// Permanently removes an Identity account and user-owned personal profile data.
    /// Shared church, meeting, classroom, attendance, and audit records are preserved
    /// with user references cleared or anonymized.
    /// </summary>
    public sealed class AccountDeletionService : IAccountDeletionService
    {
        private const string ServantEntityName = "Servant";
        private const string GenericRequestMessage =
            "If an account matches this request, a confirmation link has been sent to the email address you provided. The link expires in 24 hours.";

        private readonly ProgramContext _db;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ICurrentUserContext _currentUser;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IEmailSender _emailSender;
        private readonly AccountDeletionOptions _options;
        private readonly ILogger<AccountDeletionService> _logger;

        public AccountDeletionService(
            ProgramContext db,
            UserManager<ApplicationUser> userManager,
            ICurrentUserContext currentUser,
            IUnitOfWork unitOfWork,
            IEmailSender emailSender,
            IOptions<AccountDeletionOptions> options,
            ILogger<AccountDeletionService> logger)
        {
            _db = db;
            _userManager = userManager;
            _currentUser = currentUser;
            _unitOfWork = unitOfWork;
            _emailSender = emailSender;
            _options = options.Value;
            _logger = logger;
        }

        /// <inheritdoc />
        public async Task DeleteCurrentAccountAsync(
            string webRootPath,
            CancellationToken cancellationToken = default)
        {
            if (!_currentUser.IsAuthenticated || string.IsNullOrWhiteSpace(_currentUser.UserId))
                throw new UnauthorizedAccessException("Authentication is required.");

            await DeleteAccountByUserIdAsync(
                _currentUser.UserId,
                webRootPath,
                cancellationToken);
        }

        /// <inheritdoc />
        public async Task<AccountDeletionRequestResponseDto> RequestDeletionAsync(
            CreateAccountDeletionRequestDto dto,
            string? requestIp,
            CancellationToken cancellationToken = default)
        {
            if (dto == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    [""] = new[] { "Request body is required." }
                });

            var email = NormalizeEmail(dto.Email);
            if (email == null)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Email"] = new[] { "A valid email address is required." }
                });
            }

            if (string.IsNullOrWhiteSpace(_options.PublicBaseUrl))
            {
                throw new InvalidOperationException(
                    "Missing required configuration 'AccountDeletion:PublicBaseUrl'.");
            }

            var response = new AccountDeletionRequestResponseDto
            {
                Message = GenericRequestMessage
            };

            var user = await FindAccountForDeletionRequestAsync(
                email,
                dto.PhoneNumber,
                cancellationToken);

            var organizationHint = Truncate(dto.ChurchOrMeetingName?.Trim(), 200);

            if (user == null)
            {
                _logger.LogInformation(
                    "Account deletion request produced no match. EmailDomain={EmailDomain} OrganizationHint={OrganizationHint}",
                    GetEmailDomain(email),
                    organizationHint);
                return response;
            }

            // When the account already has an Identity email, the request must prove
            // ownership of that address — not an arbitrary inbox.
            if (!string.IsNullOrWhiteSpace(user.Email)
                && !string.Equals(
                    user.NormalizedEmail,
                    email.ToUpperInvariant(),
                    StringComparison.Ordinal))
            {
                _logger.LogInformation(
                    "Account deletion request email did not match stored Identity email. UserId={UserId}",
                    user.Id);
                return response;
            }

            var rawToken = CreateToken();
            var tokenHash = HashToken(rawToken);
            var now = DateTime.UtcNow;
            var lifetimeHours = Math.Clamp(_options.TokenLifetimeHours, 1, 168);

            var pending = await _db.AccountDeletionRequests
                .Where(r =>
                    r.UserId == user.Id &&
                    r.Status == AccountDeletionRequestStatus.PendingVerification)
                .ToListAsync(cancellationToken);
            foreach (var prior in pending)
                prior.Status = AccountDeletionRequestStatus.Cancelled;

            var request = new AccountDeletionRequest
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                Email = email,
                TokenHash = tokenHash,
                Status = AccountDeletionRequestStatus.PendingVerification,
                CreatedAtUtc = now,
                ExpiresAtUtc = now.AddHours(lifetimeHours),
                RequestIp = Truncate(requestIp, 64)
            };
            _db.AccountDeletionRequests.Add(request);
            await _unitOfWork.SaveChangesAsync();

            var confirmUrl = BuildConfirmUrl(rawToken);
            await _emailSender.SendAsync(
                email,
                "Confirm My Church account deletion",
                BuildPlainTextEmail(confirmUrl, lifetimeHours),
                BuildHtmlEmail(confirmUrl, lifetimeHours),
                cancellationToken);

            _logger.LogInformation(
                "Account deletion verification emailed. RequestId={RequestId} UserId={UserId} ExpiresAtUtc={ExpiresAtUtc} OrganizationHint={OrganizationHint}",
                request.Id,
                user.Id,
                request.ExpiresAtUtc,
                organizationHint);

            return response;
        }

        /// <inheritdoc />
        public async Task ConfirmDeletionAsync(
            ConfirmAccountDeletionRequestDto dto,
            string webRootPath,
            CancellationToken cancellationToken = default)
        {
            if (dto == null || string.IsNullOrWhiteSpace(dto.Token))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Token"] = new[] { "A confirmation token is required." }
                });
            }

            var tokenHash = HashToken(dto.Token.Trim());
            var request = await _db.AccountDeletionRequests
                .SingleOrDefaultAsync(r => r.TokenHash == tokenHash, cancellationToken);

            if (request == null)
                throw new NotFoundException("This confirmation link is invalid or has already been used.");

            if (request.Status == AccountDeletionRequestStatus.Completed)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Token"] = new[] { "This account deletion request was already completed." }
                });
            }

            if (request.Status != AccountDeletionRequestStatus.PendingVerification)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Token"] = new[] { "This confirmation link is no longer valid." }
                });
            }

            if (request.ExpiresAtUtc <= DateTime.UtcNow)
            {
                request.Status = AccountDeletionRequestStatus.Expired;
                await _unitOfWork.SaveChangesAsync();
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Token"] = new[]
                    {
                        "This confirmation link has expired. Submit a new deletion request."
                    }
                });
            }

            var userStillExists = await _userManager.Users
                .IgnoreQueryFilters()
                .AnyAsync(u => u.Id == request.UserId, cancellationToken);
            if (!userStillExists)
            {
                request.Status = AccountDeletionRequestStatus.Cancelled;
                await _unitOfWork.SaveChangesAsync();
                throw new NotFoundException("Account not found.");
            }

            request.ConfirmedAtUtc = DateTime.UtcNow;
            await _unitOfWork.SaveChangesAsync();

            await DeleteAccountByUserIdAsync(
                request.UserId,
                webRootPath,
                cancellationToken);

            // Cascade delete removes the request row with the user; if anything remains, mark done.
            var leftover = await _db.AccountDeletionRequests
                .SingleOrDefaultAsync(r => r.Id == request.Id, cancellationToken);
            if (leftover != null)
            {
                leftover.Status = AccountDeletionRequestStatus.Completed;
                leftover.CompletedAtUtc = DateTime.UtcNow;
                await _unitOfWork.SaveChangesAsync();
            }
        }

        private async Task DeleteAccountByUserIdAsync(
            string userId,
            string webRootPath,
            CancellationToken cancellationToken)
        {
            var user = await _userManager.Users
                .IgnoreQueryFilters()
                .SingleOrDefaultAsync(u => u.Id == userId, cancellationToken);

            if (user == null)
                throw new NotFoundException("Account not found.");

            var imageFileNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            AddSafeFileName(imageFileNames, user.ImageFileName);

            try
            {
                await _unitOfWork.ExecuteInTransactionAsync(async () =>
                {
                    var servant = await _db.Servants
                        .IgnoreQueryFilters()
                        .SingleOrDefaultAsync(
                            s => s.ApplicationUserId == userId,
                            cancellationToken);

                    if (servant != null)
                    {
                        AddSafeFileName(imageFileNames, servant.ImageFileName);
                        await RemoveServantLinksAndPersonalDataAsync(
                            servant.Id,
                            cancellationToken);
                        _db.Servants.Remove(servant);
                    }

                    // Preserve workflow history without retaining a deleted account identifier.
                    var approvals = await _db.Users
                        .IgnoreQueryFilters()
                        .Where(u => u.ApprovedByUserId == userId)
                        .ToListAsync(cancellationToken);
                    foreach (var approval in approvals)
                        approval.ApprovedByUserId = null;

                    // Preserve shared definitions/values while anonymizing creator metadata.
                    var definitions = await _db.CustomFieldDefinitions
                        .IgnoreQueryFilters()
                        .Where(d => d.CreatedBy == userId)
                        .ToListAsync(cancellationToken);
                    foreach (var definition in definitions)
                        definition.CreatedBy = null;

                    var values = await _db.CustomFieldValues
                        .IgnoreQueryFilters()
                        .Where(v => v.CreatedBy == userId)
                        .ToListAsync(cancellationToken);
                    foreach (var value in values)
                        value.CreatedBy = null;

                    await _unitOfWork.SaveChangesAsync();

                    // UserManager removes Identity roles, claims, logins, tokens, and the user.
                    var identityResult = await _userManager.DeleteAsync(user);
                    if (!identityResult.Succeeded)
                    {
                        var errors = string.Join(
                            "; ",
                            identityResult.Errors.Select(e => e.Description));
                        throw new InvalidOperationException(
                            $"The account could not be deleted: {errors}");
                    }

                    DeleteProfileImages(webRootPath, imageFileNames);
                });

                _logger.LogInformation(
                    "Account deletion completed. UserId={UserId}, DeletedAtUtc={DeletedAtUtc}",
                    userId,
                    DateTime.UtcNow);
            }
            catch (Exception exception)
            {
                _logger.LogError(
                    exception,
                    "Account deletion failed and was rolled back. UserId={UserId}",
                    userId);
                throw;
            }
        }

        private async Task<ApplicationUser?> FindAccountForDeletionRequestAsync(
            string normalizedEmail,
            string? phoneNumber,
            CancellationToken cancellationToken)
        {
            var byEmail = await _userManager.Users
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(
                    u => u.NormalizedEmail == normalizedEmail.ToUpperInvariant(),
                    cancellationToken);
            if (byEmail != null)
                return byEmail;

            if (string.IsNullOrWhiteSpace(phoneNumber))
                return null;

            var candidates = PhoneNumberNormalizer.GetLookupCandidates(phoneNumber);
            if (candidates.Count == 0)
                return null;

            return await _userManager.Users
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(
                    u => u.PhoneNumber != null && candidates.Contains(u.PhoneNumber),
                    cancellationToken);
        }

        private string BuildConfirmUrl(string rawToken)
        {
            var baseUrl = (_options.PublicBaseUrl ?? string.Empty).Trim().TrimEnd('/');
            if (string.IsNullOrWhiteSpace(baseUrl))
            {
                throw new InvalidOperationException(
                    "Missing required configuration 'AccountDeletion:PublicBaseUrl'.");
            }

            return $"{baseUrl}/account-deletion?token={Uri.EscapeDataString(rawToken)}";
        }

        private static string BuildPlainTextEmail(string confirmUrl, int lifetimeHours) =>
            "You requested deletion of your My Church account.\r\n\r\n" +
            "If you made this request, open the link below to permanently delete your account. " +
            $"This link expires in {lifetimeHours} hours.\r\n\r\n" +
            confirmUrl +
            "\r\n\r\nIf you did not request this, ignore this email. Your account will not be deleted.";

        private static string BuildHtmlEmail(string confirmUrl, int lifetimeHours) =>
            "<p>You requested deletion of your <strong>My Church</strong> account.</p>" +
            "<p>If you made this request, open the link below to permanently delete your account. " +
            $"This link expires in {lifetimeHours} hours.</p>" +
            $"<p><a href=\"{confirmUrl}\">Confirm account deletion</a></p>" +
            "<p>If you did not request this, ignore this email. Your account will not be deleted.</p>";

        private static string? NormalizeEmail(string? email)
        {
            if (string.IsNullOrWhiteSpace(email))
                return null;

            var trimmed = email.Trim();
            return trimmed.Contains('@', StringComparison.Ordinal) ? trimmed : null;
        }

        private static string GetEmailDomain(string email)
        {
            var at = email.LastIndexOf('@');
            return at >= 0 && at < email.Length - 1 ? email[(at + 1)..] : "(none)";
        }

        private static string CreateToken()
        {
            Span<byte> bytes = stackalloc byte[32];
            RandomNumberGenerator.Fill(bytes);
            return Convert.ToBase64String(bytes)
                .TrimEnd('=')
                .Replace('+', '-')
                .Replace('/', '_');
        }

        private static string HashToken(string rawToken)
        {
            var hash = SHA256.HashData(Encoding.UTF8.GetBytes(rawToken));
            return Convert.ToHexString(hash);
        }

        private static string? Truncate(string? value, int maxLength)
        {
            if (string.IsNullOrEmpty(value))
                return value;
            return value.Length <= maxLength ? value : value[..maxLength];
        }

        private async Task RemoveServantLinksAndPersonalDataAsync(
            int servantId,
            CancellationToken cancellationToken)
        {
            var churches = await _db.Churches
                .IgnoreQueryFilters()
                .Where(c => c.PastorId == servantId)
                .ToListAsync(cancellationToken);
            foreach (var church in churches)
                church.PastorId = null;

            var meetings = await _db.Meetings
                .IgnoreQueryFilters()
                .Where(m => m.LeaderServantId == servantId)
                .ToListAsync(cancellationToken);
            foreach (var meeting in meetings)
                meeting.LeaderServantId = null;

            var classrooms = await _db.Classrooms
                .IgnoreQueryFilters()
                .Where(c => c.LeaderServantId == servantId)
                .ToListAsync(cancellationToken);
            foreach (var classroom in classrooms)
                classroom.LeaderServantId = null;

            var sessions = await _db.AttendanceSessions
                .IgnoreQueryFilters()
                .Where(s => s.TakenByServantId == servantId)
                .ToListAsync(cancellationToken);
            foreach (var session in sessions)
                session.TakenByServantId = null;

            var assignments = await _db.ClassroomServants
                .IgnoreQueryFilters()
                .Where(cs => cs.ServantId == servantId)
                .ToListAsync(cancellationToken);
            _db.ClassroomServants.RemoveRange(assignments);

            var personalCustomValues = await _db.CustomFieldValues
                .IgnoreQueryFilters()
                .Where(v =>
                    v.EntityName == ServantEntityName &&
                    v.EntityId == servantId)
                .ToListAsync(cancellationToken);
            _db.CustomFieldValues.RemoveRange(personalCustomValues);
        }

        private static void AddSafeFileName(ISet<string> files, string? fileName)
        {
            if (string.IsNullOrWhiteSpace(fileName))
                return;

            var key = fileName.Trim().Replace('\\', '/').TrimStart('/');
            if (key.Split('/').Any(segment => segment is "" or "." or ".."))
                return;

            files.Add(key);
        }

        private static void DeleteProfileImages(
            string webRootPath,
            IEnumerable<string> fileNames)
        {
            if (string.IsNullOrWhiteSpace(webRootPath))
                return;

            var root = Path.GetFullPath(webRootPath);
            var imagesRoot = Path.GetFullPath(Path.Combine(root, "images"));
            var uploadsRoot = Path.GetFullPath(Path.Combine(root, "uploads"));
            foreach (var fileKey in fileNames)
            {
                DeleteIfContained(
                    imagesRoot,
                    Path.Combine(imagesRoot, Path.GetFileName(fileKey)));
                DeleteIfContained(
                    uploadsRoot,
                    Path.Combine(
                        uploadsRoot,
                        fileKey.Replace('/', Path.DirectorySeparatorChar)));
            }
        }

        private static void DeleteIfContained(string root, string candidate)
        {
            var fullRoot = Path.GetFullPath(root)
                .TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar)
                + Path.DirectorySeparatorChar;
            var fullPath = Path.GetFullPath(candidate);

            if (!fullPath.StartsWith(fullRoot, StringComparison.OrdinalIgnoreCase))
                return;

            if (File.Exists(fullPath))
                File.Delete(fullPath);
        }
    }
}
