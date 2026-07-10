using Church.BLL.DTOS;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Church.BLL.DTOS.ClsssroomDtos;


namespace Church.BLL.Manager.Interfaces
{
    public interface IClassroomManager
    {
        Task<List<ClassroomReadDTO>> GetVisibleClassrooms(int? meetingId = null);
        Task<int> AddAsync(ClassroomAddDTO classroom);
        Task UpdateAsync(int id, ClassroomUpdateDTO dto, bool generateDefaults = false);
        Task DeleteAsync(int id);
        Task<List<SelectOptionDTO>> GetClassroomsForSelection();

    }
}
