using AutoMapper;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Repository;
using SunDaySchools.DAL.Repository.Implementations;
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
        private readonly IServantRepository _servantRepository;
        private readonly IMapper _mapper;
        public ServantManager(IServantRepository sarventReposatory, IMapper mapper)
        {
            _servantRepository = sarventReposatory;
            _mapper = mapper;
        }
        public IEnumerable<ServantReadDTO> GetAll()
        {
            var servants = _servantRepository.GetAll().ToList();
            return _mapper.Map<IEnumerable<ServantReadDTO>>(servants);
        }
        public ServantReadDTO? GetById(int id)
        {
            var servant = _servantRepository.GetById(id);
            if (servant == null) return null;

            return _mapper.Map<ServantReadDTO>(servant);
        }
        public ServantReadDTO? GetByApplicationUserId(string applicationUserId)
        {
            var servant = _servantRepository.GetByApplicationUserId(applicationUserId);
            if (servant == null) return null;

            return _mapper.Map<ServantReadDTO>(servant);
        }

        //public void Add(ServantAddDTO servantDto)
        //{
        //    var existing = _servantRepository.GetByApplicationUserId(servantDto.ApplicationUserId);
        //    if (existing != null)
        //    {
        //        throw new ValidationException(new Dictionary<string, string[]>
        //        {
        //            ["ApplicationUserId"] = new[] { "This user already has a servant profile." }
        //        });
        //    }

            var servant = _mapper.Map<Servant>(servantDto);
            _servantRepository.Add(servant);

        }

        public void Update(ServantUpdateDTO servantUpdateDTO)
        {
            var existing = _servantRepository.GetById(servantUpdateDTO.Id);

            if (existing == null)
                throw new NotFoundException($"Servant with id {servantUpdateDTO.Id} not found.");

            _mapper.Map(servantUpdateDTO, existing);
            _servantRepository.Update(existing);
        }

        public void Delete(int id)
        {
            var existing = _servantRepository.GetById(id);
            if (existing == null)
                throw new NotFoundException($"Servant with id {id} not found.");

            _servantRepository.Delete(id);
        }

    }
}
