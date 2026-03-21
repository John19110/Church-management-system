using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Repository.Implementations;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;


namespace SunDaySchools.BLL.Manager.Implementations
{
    public class AdminManager : IAdminManager
    {

        
    private readonly IAdminRepository _adminRepository;
    private readonly IMapper _mapper;
    private readonly UserManager<ApplicationUser> _usermanager;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly IAccountManager _accountManager;


        public AdminManager(IAdminRepository adminRepository,IMapper mapper, UserManager<ApplicationUser> usermanager, IHttpContextAccessor httpContextAccessor,IAccountManager accountManager)
        {
            _adminRepository = adminRepository;
            _mapper = mapper;
            _usermanager = usermanager;
            _httpContextAccessor = httpContextAccessor;
            _accountManager = accountManager;
        }

        public async Task AssignClassToServant(int ServantId, int ClassroomId)
        {
            var (servant, classroom) = await _adminRepository.AssignClassToServantAsync(ServantId, ClassroomId);

            if (servant is null)
                throw new NotFoundException($"Servant with id : {ServantId} not found");

            if (classroom is null)
                throw new NotFoundException($"Classroom with id : {ClassroomId} not found");


            if (servant.Classrooms.Contains(classroom))
            {
                throw new Exception("Servant is already assigned to this class");
            }


            servant.Classrooms.Add( classroom);

            if (!classroom.Servants.Any(s => s.Id == servant.Id))
            {
                classroom.Servants.Add(servant);
            }

          await  _adminRepository.SaveAsync();

        }

        public async Task AddServant(AdminAddServantDTO servantDto)
        {
            var registerDTO = _mapper.Map<RegisterServantDTO>(servantDto.Account);

            // 🔥 FIX: pass image
            registerDTO.Image = servantDto.Servant.Image;

            // 🔐 Get ChurchId safely
            var claim = _httpContextAccessor.HttpContext?.User?.FindFirst("ChurchId");

            if (claim == null)
                throw new UnauthorizedAccessException("ChurchId claim is missing");

            if (!int.TryParse(claim.Value, out var churchId))
                throw new UnauthorizedAccessException("Invalid ChurchId");

            registerDTO.ChurchId = churchId;

            // ✅ Register
          var CreatedUserToken=  await _accountManager.RegisterServant(registerDTO);


            var handler = new JwtSecurityTokenHandler();
            var jwtToken = handler.ReadJwtToken(CreatedUserToken);

            // Extract userId
            var userIdClaim = jwtToken.Claims
                .FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier);

            var userId = userIdClaim?.Value;
            var user = await _usermanager.FindByIdAsync(userId);

            user.IsApproved = true;

            await _usermanager.UpdateAsync(user);



            // (Optional later) assign classrooms
        }
        public async Task<List<PendingServantDTO>> GetPendingServants()
        {
            var claim = _httpContextAccessor.HttpContext?.User?.FindFirst("ChurchId");

            if (claim == null)
                throw new UnauthorizedAccessException("ChurchId claim is missing");

            var churchId = int.Parse(claim.Value);

            var users = await _usermanager.Users
                .Where(u => !u.IsApproved && u.ChurchId == churchId)
                .Select(u => new PendingServantDTO
                {
                    Id = u.Id,
                    Name = u.UserName,
                    PhoneNumber = u.PhoneNumber
                })
                .ToListAsync();

            return users;
        }
        public async Task ApproveServant(string userId)
        {
            var user = await _usermanager.FindByIdAsync(userId);

            if (user == null)
                throw new NotFoundException($"User with id {userId} not found.");

            if (user.IsApproved)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["User"] = new[] { "User is already approved." }
                });

            user.IsApproved = true;

            var result = await _usermanager.UpdateAsync(user);

            if (!result.Succeeded)
            {
                var errors = result.Errors
                    .GroupBy(e => e.Code)
                    .ToDictionary(
                        g => g.Key,
                        g => g.Select(e => e.Description).ToArray()
                    );

                throw new ValidationException(errors);
            }
        }

        public async Task RejectServant(string userId)
        {
            var user = await _usermanager.FindByIdAsync(userId);

            if (user == null)
                throw new NotFoundException($"User with id {userId} not found.");

            if (user.IsApproved)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["User"] = new[] { "Approved users cannot be rejected." }
                });

            var result = await _usermanager.DeleteAsync(user);

            if (!result.Succeeded)
            {
                var errors = result.Errors
                    .GroupBy(e => e.Code)
                    .ToDictionary(
                        g => g.Key,
                        g => g.Select(e => e.Description).ToArray()
                    );

                throw new ValidationException(errors);
            }
        }

    }
       }
