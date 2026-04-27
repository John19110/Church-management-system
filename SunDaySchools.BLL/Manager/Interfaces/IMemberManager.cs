using SunDaySchools.BLL.DTOS;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface IMemberManager
    {
        Task<IEnumerable<MemberReadDTO>> GetAllAsync();

        Task<IEnumerable<MemberReadDTO>> GetSpecificClassroomAsync(int classroomId);

        Task<MemberReadDTO?> GetByIdAsync(int id);
         Task<List<SelectOptionDTO>> GetMembersForSelection();

        Task AddAsync(MemberAddDTO member, int classroomId);

        Task UpdateAsync(MemberUpdateDTO member);

        Task UpdateImageAsync(int id, string imageFileName, string imageUrl);

        Task DeleteAsync(int id);
    }
}