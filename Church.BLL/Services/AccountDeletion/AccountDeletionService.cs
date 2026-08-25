using Church.BLL.Abstractions;
using Church.BLL.Exceptions;
using Church.DAL.DBcontext;
using Church.DAL.Repository.Interfaces;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

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

        private readonly ProgramContext _db;
        private readonly UserManager<Church.DAL.Models.ApplicationUser> _userManager;
        private readonly ICurrentUserContext _currentUser;
        private readonly IUnitOfWork _unitOfWork;
        private readonly ILogger<AccountDeletionService> _logger;

        public AccountDeletionService(
            ProgramContext db,
            UserManager<Church.DAL.Models.ApplicationUser> userManager,
            ICurrentUserContext currentUser,
            IUnitOfWork unitOfWork,
            ILogger<AccountDeletionService> logger)
        {
            _db = db;
            _userManager = userManager;
            _currentUser = currentUser;
            _unitOfWork = unitOfWork;
            _logger = logger;
        }

        /// <inheritdoc />
        public async Task DeleteCurrentAccountAsync(
            string webRootPath,
            CancellationToken cancellationToken = default)
        {
            if (!_currentUser.IsAuthenticated || string.IsNullOrWhiteSpace(_currentUser.UserId))
                throw new UnauthorizedAccessException("Authentication is required.");

            var userId = _currentUser.UserId;
            var user = await _userManager.Users
                .IgnoreQueryFilters()
                .SingleOrDefaultAsync(u => u.Id == userId, cancellationToken);

            if (user == null)
                throw new NotFoundException("Account not found.");

            var imageFileNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            AddSafeFileName(imageFileNames, user.ImageFileName);

            await _unitOfWork.BeginTransactionAsync();
            try
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
                await _unitOfWork.CommitAsync();

                _logger.LogInformation(
                    "Account deletion completed. UserId={UserId}, DeletedAtUtc={DeletedAtUtc}",
                    userId,
                    DateTime.UtcNow);
            }
            catch (Exception exception)
            {
                await _unitOfWork.RollbackAsync();
                _logger.LogError(
                    exception,
                    "Account deletion failed and was rolled back. UserId={UserId}",
                    userId);
                throw;
            }
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
