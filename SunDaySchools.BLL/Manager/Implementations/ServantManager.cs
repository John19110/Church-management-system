using AutoMapper;
using Microsoft.AspNetCore.Http;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class ServantManager : IServantManager
    {
        private readonly IServantRepository _servantRepository;
        private readonly IHttpContextAccessor _httpContextAccessor;

        private readonly IMapper _mapper;

        public ServantManager(IServantRepository servantRepository, IMapper mapper, IHttpContextAccessor httpContextAccessor)
        {
            _servantRepository = servantRepository;
            _mapper = mapper;
            _httpContextAccessor = httpContextAccessor;

        }

        public async Task<IEnumerable<ServantReadDTO>> GetAllAsync()
        {
            var servants = await _servantRepository.GetAllAsync();
            return _mapper.Map<IEnumerable<ServantReadDTO>>(servants);
        }

        public async Task<List<SelectOptionDTO>> GetServantsForSelection()
        {
            var servants = await _servantRepository.GetAllAsync();

            return servants.Select(s => new SelectOptionDTO
            {
                Id = s.Id,
                Name = s.Name
            }).ToList();
        }
        public async Task<ServantReadDTO?> GetByIdAsync(int id)
        {
            var servant = await _servantRepository.GetByIdAsync(id);
            if (servant == null)
                return null;

            return _mapper.Map<ServantReadDTO>(servant);
        }

       
        public async Task UpdateAsync(ServantUpdateDTO servantUpdateDTO)
        {
            var existing = await _servantRepository.GetByIdAsync(servantUpdateDTO.Id);

            if (existing == null)
                throw new NotFoundException($"Servant with id {servantUpdateDTO.Id} not found.");

            _mapper.Map(servantUpdateDTO, existing);
            await _servantRepository.UpdateAsync(existing);
        }

        public async Task DeleteAsync(int id)
        {
            var existing = await _servantRepository.GetByIdAsync(id);

            if (existing == null)
                throw new NotFoundException($"Servant with id {id} not found.");

            await _servantRepository.DeleteAsync(id);
        }
    }
}