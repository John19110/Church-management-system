using SunDaySchools.BLL.DTOS;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface IServantManager
    {
        IEnumerable<ServantReadDTO> GetAll();

        ServantReadDTO? GetById(int id);
        ServantReadDTO? GetByApplicationUserId(string applicationUserId);

     //   void Add(ServantAddDTO Servant);
        Task Update(ServantUpdateDTO servant);
        Task<IEnumerable<Classroom>> GetClassesByServantId(int servantId);
        void Delete(int id);


    }
}
