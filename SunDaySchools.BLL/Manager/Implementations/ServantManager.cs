using AutoMapper;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Abstractions;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchoolsDAL.Models;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class ServantManager : IServantManager
    {
        private readonly IServantRepository _servantRepository;
        private readonly ITenantContext _tenantContext;
        private readonly IAccountManager _accountManager;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IMapper _mapper;

        public ServantManager(
            IServantRepository servantRepository,
            ITenantContext tenantContext,
            IMapper mapper,
            IAccountManager accountManager,
            UserManager<ApplicationUser> usermanager)
        {
            _servantRepository = servantRepository;
            _tenantContext = tenantContext;
            _mapper = mapper;
            _accountManager = accountManager;
            _userManager = usermanager;
        }

        public async Task AddAsync(AdminAddServantDTO servantDto, string webRootPath)
        {
            var registerDTO = _mapper.Map<RegisterServantDTO>(servantDto.Account);
            registerDTO.Image = servantDto.Servant.Image;

            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing");

            registerDTO.ChurchId = churchId;

            await _accountManager.RegisterServant(registerDTO, webRootPath);

            var phone = registerDTO.PhoneNumber.Trim().Replace(" ", "");
            var user = await _userManager.Users.FirstOrDefaultAsync(u => u.PhoneNumber == phone);
            if (user == null)
                throw new InvalidOperationException("Servant user was not created.");

            user.IsApproved = true;
            user.IsPhoneVerified = true;
            user.PhoneNumberConfirmed = true;
            await _userManager.UpdateAsync(user);
        }

        public async Task<IEnumerable<ServantReadDTO>> GetAllAsync()
        {
            var servants = await _servantRepository.GetAllAsync();
            return _mapper.Map<IEnumerable<ServantReadDTO>>(servants);
        }

        public async Task<List<SelectOptionDTO>> GetServantsForSelection()
        {
            var servants = await _servantRepository.GetServantsForSelection();

            return servants.Select(s => new SelectOptionDTO
            {
                Id = s.Id,
                Name = s.Item2
            }).ToList();
        }

        public async Task<ServantReadDTO?> GetByIdAsync(int id)
        {
            if (id <= 0)
                return null;

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

        public async Task<bool> DeleteAsync(int id)
        {
            if (id <= 0)
                return false;

            var outcome = await _servantRepository.DeleteAsync(id);
            if (!outcome.Deleted)
                return false;

            if (!string.IsNullOrEmpty(outcome.ApplicationUserId))
            {
                var user = await _userManager.FindByIdAsync(outcome.ApplicationUserId);
                if (user != null)
                    await _userManager.UpdateSecurityStampAsync(user);
            }

            return true;
        }
    }
}
