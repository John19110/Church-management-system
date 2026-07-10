using Church.Domain;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Church.DAL.Repository.Interfaces
{
    public interface IMemberRepository
    {
        Task<IEnumerable<Member>> GetAllAsync();

        Task<Member?> GetByIdAsync(int id);

        /// <summary>Member row without navigation includes (safe for unified form SQL merge).</summary>
        Task<Member?> GetByIdForFormAsync(int id);

        /// <summary>Phone contacts for form JSON; avoids Member.PhoneNumbers include + filter issues.</summary>
        Task<IReadOnlyList<(string? Relation, string? PhoneNumber)>> GetContactPhonesForFormAsync(int memberId);

        Task<List<Member>> GetByIdsAsync(List<int> ids);

        Task<List<(int Id, string Name)>> GetMembersForSelection();

        Task AddAsync(Member member);

        Task UpdateAsync(Member member);

        Task DeleteAsync(int id);

        /// <summary>
        /// Removes a member and dependent rows (exam results, custom field values).
        /// Does not open its own transaction.
        /// </summary>
        Task DeleteWithDependenciesAsync(int memberId);

        /// <summary>Deletes all members assigned to a classroom.</summary>
        Task DeleteByClassroomIdAsync(int classroomId);

        /// <summary>Deletes members scoped to a meeting (including orphans not in a classroom).</summary>
        Task DeleteByMeetingIdAsync(int meetingId);

        Task<IEnumerable<Member>> GetSpecificClassroomAsync(int classroomId);

        /// <summary>Returns all members whose <c>MeetingId</c> matches the given meeting.</summary>
        Task<IEnumerable<Member>> GetByMeetingIdAsync(int meetingId);

        Task SaveAsync();
    }
}