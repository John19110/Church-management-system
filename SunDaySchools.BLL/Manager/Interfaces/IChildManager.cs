using SunDaySchools.BLL.DTOS;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface  IChildManager
    {
        IEnumerable<ChildReadDTO> GetAll();

        IEnumerable<ChildReadDTO> GetSpecificClassroom(int ClassroomId);

        ChildReadDTO GetById(int id);
        void Add(ChildAddDTO child);
        void Update(ChildUpdateDTO child);
        void Delete(int id);
    }
}
