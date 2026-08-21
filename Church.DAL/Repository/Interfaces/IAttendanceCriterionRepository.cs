using Church.DAL.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Church.DAL.Repository.Interfaces
{
    public interface IAttendanceCriterionRepository
    {
        Task<List<AttendanceCriterion>> GetByMeetingAsync(int meetingId, bool includeDeleted = false);
        Task<AttendanceCriterion?> GetByIdAsync(int id);
        Task<AttendanceCriterion> AddAsync(AttendanceCriterion criterion);
        Task UpdateAsync(AttendanceCriterion criterion);
        Task EnsureDefaultsForMeetingAsync(int meetingId, int churchId);
    }
}
