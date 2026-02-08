using AutoMapper;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.DAL.Repository;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SunDaySchoolsDAL.Repository;

namespace SunDaySchools.BLL.Manager
{
    public class ServantManager : IServantManager
    {
        private readonly IServantRepository _sarventReposatory;
        private readonly IMapper _mapper;
        public ServantManager(IServantRepository sarventReposatory, IMapper mapper)
        {
            _sarventReposatory = sarventReposatory;
            _mapper = mapper;
        }
        public IEnumerable<ServantReadDTO> GetAll()
        {
            return _mapper.Map<IEnumerable<ServantReadDTO>>(_sarventReposatory.GetAll().ToList());
        }
        public  ServantReadDTO GetById(int id)
        {
            return _mapper.Map<ServantReadDTO>(_sarventReposatory.GetById(id));
        }

        public void Add(ServantAddDTO servant)
        {
            _sarventReposatory.Add(_mapper.Map<Servant>(servant));
        }
     public  void Update(ServantUpdateDTO ServantUpdateDTO)
        {
            _sarventReposatory.Update(_mapper.Map<ServantUpdateDTO, Servant>(ServantUpdateDTO, _sarventReposatory.GetById(ServantUpdateDTO.Id)));

        }

      public  void Delete(int id)
        {

            _sarventReposatory.Delete(id);
        }


    }
}
