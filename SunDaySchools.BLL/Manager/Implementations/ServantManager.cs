using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Models;
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
        private readonly RoleManager<IdentityRole> _roleManager;



        private readonly IMapper _mapper;

        public ServantManager(IServantRepository servantRepository,
            ProgramContext dbContext,
            IMapper mapper, IHttpContextAccessor httpContextAccessor, IAccountManager accountManager,
            UserManager<ApplicationUser> usermanager,
            RoleManager<IdentityRole> roleManager)
        {
            _servantRepository = servantRepository;
            _dbContext = dbContext;
            _mapper = mapper;
            _httpContextAccessor = httpContextAccessor;
            _accountManager = accountManager;
            _userManager = usermanager;
            _roleManager = roleManager;
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
        /// Deletes a servant and all links so Identity never has the <c>Servant</c> role without a matching
        /// <see cref="Servant"/> row: clears restrictive FKs, removes <see cref="ClassroomServant"/> rows,
        /// deletes <c>AspNetUserRoles</c> for role <c>Servant</c>, removes the <c>Servants</c> row, and
        /// bumps the user security stamp so existing sessions can be rejected.
        /// </summary>
        public async Task<bool> DeleteAsync(int id)
        {
            if (id <= 0)
                return false;

            await using var transaction = await _dbContext.Database.BeginTransactionAsync();
            try
            {
                var servant = await _dbContext.Servants
                    .IgnoreQueryFilters()
                    .FirstOrDefaultAsync(s => s.Id == id);

                if (servant == null)
                {
                    await transaction.RollbackAsync();
                    return false;
                }

                var applicationUserId = servant.ApplicationUserId;

                // Clear optional FKs that use DeleteBehavior.Restrict toward Servant
                await _dbContext.AttendanceSessions
                    .IgnoreQueryFilters()
                    .Where(s => s.TakenByServantId == id)
                    .ExecuteUpdateAsync(s => s.SetProperty(x => x.TakenByServantId, (int?)null));

                await _dbContext.Meetings
                    .IgnoreQueryFilters()
                    .Where(m => m.LeaderServantId == id)
                    .ExecuteUpdateAsync(s => s.SetProperty(x => x.LeaderServantId, (int?)null));

                await _dbContext.Classrooms
                    .IgnoreQueryFilters()
                    .Where(c => c.LeaderServantId == id)
                    .ExecuteUpdateAsync(s => s.SetProperty(x => x.LeaderServantId, (int?)null));

                await _dbContext.Churches
                    .Where(ch => ch.PastorId == id)
                    .ExecuteUpdateAsync(s => s.SetProperty(x => x.PastorId, (int?)null));

                // PhoneCall maps Servant with optional FK; clear if present (column may exist without CLR property).
                await _dbContext.Database.ExecuteSqlInterpolatedAsync(
                    $"UPDATE PhoneCalls SET ServantId = NULL WHERE ServantId = {id}");

                await _dbContext.ClassroomServants
                    .IgnoreQueryFilters()
                    .Where(cs => cs.ServantId == id)
                    .ExecuteDeleteAsync();

                var servantRole = await _roleManager.FindByNameAsync(ServantRoleName);
                if (servantRole != null)
                {
                    await _dbContext.UserRoles
                        .Where(ur => ur.UserId == applicationUserId && ur.RoleId == servantRole.Id)
                        .ExecuteDeleteAsync();
                }

                _dbContext.Servants.Remove(servant);
                await _dbContext.SaveChangesAsync();

                var user = await _userManager.FindByIdAsync(applicationUserId);
                if (user != null)
                    await _userManager.UpdateSecurityStampAsync(user);

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