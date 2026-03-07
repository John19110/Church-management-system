using AutoMapper;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Repository;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Implementations
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
        public void Update(ServantUpdateDTO servantUpdateDTO)
        {
            var existing = _sarventReposatory.GetById(servantUpdateDTO.Id);

            if (existing == null)
                throw new NotFoundException($"Servant with id {servantUpdateDTO.Id} not found.");

            _mapper.Map(servantUpdateDTO, existing);
            _sarventReposatory.Update(existing);
        }

        public  void Delete(int id)
        {

            _sarventReposatory.Delete(id);
        }


    }
}
