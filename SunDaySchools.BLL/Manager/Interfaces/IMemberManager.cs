using SunDaySchools.BLL.DTOS;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface  IMemberManager
    {
        IEnumerable<MemberReadDTO> GetAll();

        IEnumerable<MemberReadDTO> GetSpecificClassroom(int ClassroomId);

        MemberReadDTO GetById(int id);
        void Add(MemberAddDTO child);
        void Update(MemberUpdateDTO child);
        void Delete(int id);
    }
}
