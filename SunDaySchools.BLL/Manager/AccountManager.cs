using Microsoft.AspNetCore.Identity;
using SunDaySchools.BLL.DTOS.AccountDtos;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SunDaySchoolsDAL.Models;
using System.Security.Claims;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;

namespace SunDaySchools.BLL.Manager
{
    public class AccountManager : IAccountManager
    {
        private readonly UserManager<ApplicationUser> _usermanager;
        private readonly IConfiguration _configuration;
      public   AccountManager(UserManager<ApplicationUser>usermagaer, IConfiguration configuration)
        {


            _usermanager = usermagaer;
            _configuration = configuration;
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
            var claims = await _usermanager.GetClaimsAsync(user); 

                return GenerateToken(claims);
        }

        public async Task<string> Register(RegisterDTO registerDto)
        {
            ApplicationUser user = new ApplicationUser();
            //save email and passwrod
            user.Email = registerDto.Email;
            user.UserName = registerDto.Name;

            //save password and create user 
            var resutlt=  await _usermanager.CreateAsync(user, registerDto.Password);

            if (resutlt.Succeeded)

            {
                //create claims
                List<Claim> claims = new List<Claim>();
                claims.Add(new Claim("Name", registerDto.Name));
                claims.Add(new Claim("Role", registerDto.Role));

                await _usermanager.AddClaimsAsync(user, claims);

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


    }
}
