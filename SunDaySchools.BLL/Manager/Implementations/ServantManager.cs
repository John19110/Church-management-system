using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;
using SunDaySchoolsDAL.Models;
using System.Collections.Generic;
using System.Linq;
using System.IdentityModel.Tokens.Jwt;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class ServantManager : IServantManager
    {
        private const string ServantRoleName = "Servant";

        private readonly IServantRepository _servantRepository;
        private readonly ProgramContext _dbContext;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IAccountManager _accountManager;
        private readonly UserManager<ApplicationUser> _userManager;



        private readonly IMapper _mapper;

        public ServantManager(IServantRepository servantRepository,
            ProgramContext dbContext,
            IMapper mapper, IHttpContextAccessor httpContextAccessor, IAccountManager accountManager,
           UserManager<ApplicationUser> usermanager)
        {
            _servantRepository = servantRepository;
            _dbContext = dbContext;
            _mapper = mapper;
            _httpContextAccessor = httpContextAccessor;
            _accountManager = accountManager;
            _userManager = usermanager;
        }

        public async Task AddAsync(AdminAddServantDTO servantDto, string webRootPath)
        {
            var registerDTO = _mapper.Map<RegisterServantDTO>(servantDto.Account);
            registerDTO.Image = servantDto.Servant.Image;

            // ChurchId logic
            var claim = _httpContextAccessor.HttpContext?.User?.FindFirst("ChurchId");
            if (claim == null) throw new UnauthorizedAccessException("ChurchId claim is missing");
            if (!int.TryParse(claim.Value, out var churchId)) throw new UnauthorizedAccessException("Invalid ChurchId");
            registerDTO.ChurchId = churchId;

            // ✅ Pass webRootPath here
            var createdUserToken = await _accountManager.RegisterServant(registerDTO, webRootPath);

            var handler = new JwtSecurityTokenHandler();
            var jwtToken = handler.ReadJwtToken(createdUserToken);

            var userId = jwtToken.Claims.FirstOrDefault(c => c.Type == JwtRegisteredClaimNames.Sub)?.Value;
            if (string.IsNullOrEmpty(userId))
                throw new InvalidOperationException("Issued token is missing sub (user id) claim.");

            var user = await _userManager.FindByIdAsync(userId);

            user.IsApproved = true;
            await _userManager.UpdateAsync(user);

            // Optional: assign classrooms
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

        /// <summary>
        /// Deletes the servant row and removes the Identity <c>Servant</c> role from the linked user so
        /// tokens never imply a servant profile without a <see cref="Servant"/> row.
        /// </summary>
        public async Task<bool> DeleteAsync(int id)
        {
            if (id <= 0)
                return false;

            await using var transaction = await _dbContext.Database.BeginTransactionAsync();
            try
            {
                var servant = await _dbContext.Servants
                    .FirstOrDefaultAsync(s => s.Id == id);

                if (servant == null)
                {
                    await transaction.RollbackAsync();
                    return false;
                }

                var user = await _userManager.FindByIdAsync(servant.ApplicationUserId);
                if (user != null && await _userManager.IsInRoleAsync(user, ServantRoleName))
                {
                    var roleResult = await _userManager.RemoveFromRoleAsync(user, ServantRoleName);
                    if (!roleResult.Succeeded)
                    {
                        await transaction.RollbackAsync();
                        throw new InvalidOperationException(
                            "Could not remove Servant role: " +
                            string.Join("; ", roleResult.Errors.Select(e => e.Description)));
                    }
                }

                _dbContext.Servants.Remove(servant);
                await _dbContext.SaveChangesAsync();
                await transaction.CommitAsync();
                return true;
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        }
    }
}