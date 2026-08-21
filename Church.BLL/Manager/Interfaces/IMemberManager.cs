using Church.BLL.DTOS;
using Church.Domain;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Church.BLL.Manager.Interfaces
{
    public interface IMemberManager
    {
        Task<IEnumerable<MemberReadDTO>> GetAllAsync();

        Task<IEnumerable<MemberReadDTO>> GetSpecificClassroomAsync(int classroomId);

        Task<IEnumerable<MemberReadDTO>> GetByMeetingIdAsync(int meetingId);

        Task<MemberReadDTO?> GetByIdAsync(int id);
         Task<List<SelectOptionDTO>> GetMembersForSelection();

        /// <param name="classroomId">
        /// Required when the meeting uses classrooms. Omit for meeting-level members.
        /// </param>
        /// <param name="meetingId">
        /// Required when classroomId is omitted. Also used as an ownership check when
        /// classroomId is provided.
        /// </param>
        Task<int> AddAsync(MemberAddDTO member, int? classroomId = null, int? meetingId = null);

        Task UpdateAsync(MemberUpdateDTO member);

        Task UpdateImageAsync(int id, string imageFileName, string imageUrl);

        Task DeleteAsync(int id);
    }
}