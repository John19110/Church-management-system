using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Exceptions;          // <-- Add this
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class AccountManager : IAccountManager
    {
        private readonly UserManager<ApplicationUser> _usermanager;
        private readonly IConfiguration _configuration;
        private readonly IServantRepository _servantRepo;
        private readonly IChurchRepository _churchRepo;
        private readonly IAdminRepository _adminRepo; 

        public AccountManager(UserManager<ApplicationUser>usermagaer, IConfiguration configuration, IServantRepository servantRepo, IChurchRepository chruchRepo,IAdminRepository adminRepo)
        {

            _churchRepo = chruchRepo;
            _usermanager = usermagaer;
            _configuration = configuration;
            _servantRepo = servantRepo;
            _adminRepo = adminRepo;
        }

        public async Task<string> Login(LoginDTO loginDto)
        {
            // Optional: Validate DTO (though controller should handle null)
            if (loginDto == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["loginDto"] = new[] { "Login data cannot be null." }
                });


            var user = await _usermanager.FindByNameAsync(loginDto.Name);
            if (user == null)
                throw new InvalidCredentialsException();

            if (!user.IsApproved)
                return "Account waiting for church admin approval";

            var check = await _usermanager.CheckPasswordAsync(user, loginDto.Password);
            if (!check)
                throw new InvalidCredentialsException();

            var claims = await BuildJwtClaims(user);
            return GenerateToken(claims);
        }

        public async Task<string> RegisterChurchAdmin(RegisterChurchAdminDTO registerChurchAdminDTO)
        {
            if (registerChurchAdminDTO == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["registerDto"] = new[] { "Registration data cannot be null." }
                });

            // Check if user already exists
            var existingUser = await _usermanager.FindByNameAsync(registerChurchAdminDTO.Name);
            if (existingUser != null)
                throw new UserAlreadyExistsException();


            // Create the church 
            var church = new Church
            {
                Name = registerChurchAdminDTO.ChurchName
            };

             await _churchRepo.AddChurch(church);

            // Creaet the user 
            var user = new ApplicationUser
            {
                UserName = registerChurchAdminDTO.Name,
                PhoneNumber = registerChurchAdminDTO.PhoneNumber,
                IsApproved = true,
                ChurchId = church.Id
            }; 
            
            var result = await _usermanager.CreateAsync(user, registerChurchAdminDTO.Password);
            if (!result.Succeeded)
            {
                // Convert Identity errors to a ValidationException
                var errors = result.Errors
                    .GroupBy(e => e.Code) // or use a custom field name
                    .ToDictionary(
                        g => g.Key,
                        g => g.Select(e => e.Description).ToArray()
                    );
                throw new ValidationException(errors);
            }

            await _usermanager.AddToRoleAsync(user, "Admin");


            // Create the servant
            var servant = new Servant
            {
                ApplicationUserId = user.Id,
                Name = registerChurchAdminDTO.Name,
                PhoneNumber = registerChurchAdminDTO.PhoneNumber,
                ChurchId = church.Id // 🔥 THIS LINE IS MISSING


            };
            _adminRepo.AddServant(servant);

            var claims = await BuildJwtClaims(user);
            return GenerateToken(claims);
        }


        public async Task<string> RegisterServant(RegisterServantDTO registerDto)
        {
            if (registerDto == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["registerDto"] = new[] { "Registration data cannot be null." }
                });

            // Check if user already exists
            var existingUser = await _usermanager.FindByNameAsync(registerDto.Name);
            if (existingUser != null)
                throw new UserAlreadyExistsException();

            var church = await _churchRepo.GetChurchById(registerDto.ChurchId);
            if (church==null)
            {
                throw new NotFoundException($"Church with id {registerDto.ChurchId} not found."); 
           }


            var user = new ApplicationUser
            {
                UserName = registerDto.Name,
                PhoneNumber = registerDto.PhoneNumber,
                ChurchId = registerDto.ChurchId,
                IsApproved = false
            };

            var result = await _usermanager.CreateAsync(user, registerDto.Password);
            if (!result.Succeeded)
            {
                // Convert Identity errors to a ValidationException
                var errors = result.Errors
                    .GroupBy(e => e.Code) // or use a custom field name
                    .ToDictionary(
                        g => g.Key,
                        g => g.Select(e => e.Description).ToArray()
                    );
                throw new ValidationException(errors);
            }

            await _usermanager.AddToRoleAsync(user, "Servant");

            var servant = new Servant
            {
                ApplicationUserId = user.Id,
                Name = registerDto.Name,
                PhoneNumber = registerDto.PhoneNumber

            }; 

            _adminRepo.AddServant(servant);

            var claims = await BuildJwtClaims(user);
            return GenerateToken(claims);
        }



        private string GenerateToken(IList<Claim> claims)
        {
            // get secret key (string)
            var SecretKey = _configuration.GetSection("SecretKey").Value;

            // convert the secret key  from string to byte 
            var SecretKeybyte = Encoding.UTF8.GetBytes(SecretKey);

            //SecurityKey is an abstract class so we cant instiantiate it 
            //thas why we call  SymmetricSecurityKey constructor
            SecurityKey securityKey = new SymmetricSecurityKey(SecretKeybyte);

            //3
            //pass the security key and the algorithm to SigningCredentials to merge them
            SigningCredentials signingCredentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            //2
            //expire date for the token 
            var expire = DateTime.Now.AddDays(7);

            //1
            //generate the token 
                JwtSecurityToken jwtSecurityToken = new JwtSecurityToken(claims: claims, expires: expire, signingCredentials: signingCredentials);

            //convert back to string from jwtSecurityToken
            JwtSecurityTokenHandler handler = new JwtSecurityTokenHandler();

            var token = handler.WriteToken(jwtSecurityToken);

            return token;
        }

        private async Task<List<Claim>> BuildJwtClaims(ApplicationUser user)
        {
            var claims = new List<Claim>

                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id),
                    new Claim(ClaimTypes.Name, user.UserName ?? ""),
                    new Claim("ChurchId", user.ChurchId.ToString())
                  //  new Claim(ClaimTypes.UserData,user.ClassroomId)
                };

            var roles = await _usermanager.GetRolesAsync(user);
            foreach (var role in roles)
                claims.Add(new Claim(ClaimTypes.Role, role));

            return claims;
        }

    }
}
