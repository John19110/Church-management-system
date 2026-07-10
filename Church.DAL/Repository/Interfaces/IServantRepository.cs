using Church.Domain;
using Church.DAL.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Church.DAL.Repository.Interfaces
{
    public interface IServantRepository
    {
        Task<IEnumerable<Servant>> GetAllAsync();

        Task<Servant?> GetByApplicationUserIdAsync(string applicationUserId);

        Task<Servant?> GetProfileByApplicationUserIdAsync(
            string applicationUserId,
            CancellationToken cancellationToken = default);

        Task<Servant?> GetTrackedProfileByApplicationUserIdAsync(
            string applicationUserId,
            CancellationToken cancellationToken = default);

        Task SaveChangesAsync(CancellationToken cancellationToken = default);

        /// <summary>
        /// Ensures a <c>Servant</c> profile exists for the given user.
        /// If <paramref name="autoCreateMissing"/> is true, a minimal profile is created and returned.
        /// Returns <c>null</c> if missing and auto-create is disabled.
        /// </summary>
        Task<Servant?> EnsureServantProfileAsync(ApplicationUser user, bool autoCreateMissing);

        /// <summary>Whether a <c>Servants</c> row exists for this user (ignores tenant query filters for integrity checks).</summary>
        Task<bool> HasServantProfileLinkedAsync(string applicationUserId);

        Task<Servant?> GetByIdAsync(int id);

        Task<List<(int Id, string Name)>> GetServantsForSelection();


        Task<List<Servant>> GetByIdsAsync(List<int> ids);

        /// <summary>Returns approved servants whose <c>MeetingId</c> matches the given meeting.</summary>
        Task<IEnumerable<Servant>> GetByMeetingIdAsync(int meetingId);
        Task<IEnumerable<Classroom>> GetByServantIdAsync(int servantId);
        Task<List<int>> GetClassroomIdsByApplicationUserIdAsync(string applicationUserId);

        Task AddAsync(Servant servant);

        Task UpdateAsync(Servant servant);

        /// <summary>
        /// Deletes a servant and dependent links (FK clears, join rows, Servant role).
        /// Returns whether a row was deleted and the linked application user id when applicable.
        /// </summary>
        Task<ServantDeleteOutcome> DeleteAsync(int id);
    }

    public sealed class ServantDeleteOutcome
    {
        public bool Deleted { get; init; }
        public string? ApplicationUserId { get; init; }
    }
}