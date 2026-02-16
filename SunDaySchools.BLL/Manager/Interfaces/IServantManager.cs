using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SunDaySchools.BLL.DTOS;

namespace SunDaySchools.BLL.Manager.Interfaces
{
    public interface IServantManager
    {
        IEnumerable<ServantReadDTO> GetAll();

        ServantReadDTO GetById(int id);
        void Add(ServantAddDTO Servant);
        void Update(ServantUpdateDTO servant);
        void Delete(int id);


    }
}
