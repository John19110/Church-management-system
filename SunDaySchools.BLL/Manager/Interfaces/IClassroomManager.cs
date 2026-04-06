using SunDaySchools.BLL.DTOS;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SunDaySchools.BLL.DTOS.ClsssroomDtos;


namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface IClassroomManager
    {
        Task<List<ClassroomReadDTO>> GetVisibleClassrooms();
        Task AddAsync(ClassroomAddDTO classroom);

    }
}
