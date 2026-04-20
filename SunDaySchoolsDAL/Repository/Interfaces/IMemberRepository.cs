using SunDaySchools.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public interface IMemberRepository
    {
        Task<IEnumerable<Member>> GetAllAsync();

        Task<Member?> GetByIdAsync(int id);

        Task<List<Member>> GetByIdsAsync(List<int> ids);

        Task<List<(int Id, string Name)>> GetMembersForSelection();

        Task AddAsync(Member member);

        Task UpdateAsync(Member member);

        Task DeleteAsync(int id);

        Task<IEnumerable<Member>> GetSpecificClassroomAsync(int classroomId);

        Task SaveAsync();
    }
}