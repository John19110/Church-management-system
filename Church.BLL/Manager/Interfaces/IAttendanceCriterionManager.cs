using Church.BLL.DTOS.AttendanceCriteria;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Church.BLL.Manager.Interfaces
{
    public interface IAttendanceCriterionManager
    {
        Task<List<AttendanceCriterionReadDTO>> GetByMeetingAsync(int meetingId, bool includeInactive = false);
        Task<AttendanceCriterionReadDTO> AddAsync(int meetingId, AttendanceCriterionAddDTO dto);
        Task<AttendanceCriterionReadDTO> UpdateAsync(int id, AttendanceCriterionUpdateDTO dto);
        Task SoftDeleteAsync(int id);
        Task ReorderAsync(int meetingId, AttendanceCriterionReorderDTO dto);
    }
}
