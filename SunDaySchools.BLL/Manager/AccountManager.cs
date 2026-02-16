using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;
using SunDaySchoolsDAL.Repository;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager
{
    public class AccountManager : IAccountManager
    {
        private readonly UserManager<ApplicationUser> _usermanager;
        private readonly IConfiguration _configuration;
        private readonly IServantRepository _servantRepo;

        public AccountManager(UserManager<ApplicationUser>usermagaer, IConfiguration configuration, IServantRepository servantRepo)
        {


            _usermanager = usermagaer;
            _configuration = configuration;
            _servantRepo = servantRepo;
        }

        public async Task<string> Login(LoginDTO loginDto)

        {
            //search by name 
            var user = await _usermanager.FindByNameAsync(loginDto.Name);
            if (user==null)
            {
                return null;
            }
            // check password
            var check =await  _usermanager.CheckPasswordAsync(user, loginDto.Password);

            if (!check) return null;

            //return claims
            var claims = await BuildJwtClaims(user);
            return GenerateToken(claims);

        }

        public async Task<string> Register(RegisterDTO registerDto)
        {
            ApplicationUser user = new ApplicationUser();
            //save email and passwrod
            user.UserName = registerDto.Name;
            user.PhoneNumber = registerDto.PhoneNumber;

            //save password and create user 
            var resutlt=  await _usermanager.CreateAsync(user, registerDto.Password);

            if (resutlt.Succeeded)
            {
                await _usermanager.AddToRoleAsync(user, "Servant");

                // create domain profile row
                var servant = new Servant
                {
                    ApplicationUserId = user.Id,
                    Name = registerDto.Name,
                    PhoneNumber = registerDto.PhoneNumber
                };

                _servantRepo.Add(servant);

                var claims = await BuildJwtClaims(user);
                return GenerateToken(claims);
            }

            //if not succeded
            return null;
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
        new Claim(ClaimTypes.Name, user.UserName ?? "")
    };

            var roles = await _usermanager.GetRolesAsync(user);
            foreach (var role in roles)
                claims.Add(new Claim(ClaimTypes.Role, role));

            return claims;
        }

    }
}
