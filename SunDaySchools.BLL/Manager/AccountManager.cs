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
    internal class AccountManager : IaccountManager
    {
        private readonly UserManager<ApplicationUser> _usermanager;
        private readonly IConfiguration _configuration;
        AccountManager(UserManager<ApplicationUser>usermagaer, IConfiguration configuration)
        {


            _usermanager = usermagaer;
            _configuration = configuration;
        }
        public Task<string> Login(LoginDTO loginDto)
        {
            throw new NotImplementedException();
        }

        public async Task<string> Register(RegisterDTO registerDto)
        {
            ApplicationUser user = new ApplicationUser();

            user.Email = registerDto.Email;
            user.UserName = registerDto.Name;

            var resutlt=  await _usermanager.CreateAsync(user, registerDto.Password);

            if (resutlt.Succeeded)
            {
                List<Claim> claims = new List<Claim>();
                claims.Add(new Claim("Role", "Admin"));
                claims.Add(new Claim("Name", registerDto.Name));

                var SecretKey=_configuration.GetSection("SecretKey").Value;

                var SecretKeybyte = Encoding.UTF8.GetBytes(SecretKey);
                SecurityKey securityKey = new SymmetricSecurityKey(SecretKeybyte);
                SigningCredentials signingCredentials = new SigningCredentials(securityKey,SecurityAlgorithms.HmacSha256);
                var expire = DateTime.Now.AddDays(7);
                JwtSecurityToken jwtSecurityToken = new JwtSecurityToken(claims: claims, expires: expire, signingCredentials: signingCredentials);
                JwtSecurityTokenHandler handler = new JwtSecurityTokenHandler();
                var token = handler.WriteToken(jwtSecurityToken);
                return token;


            }

            return null;
        }
    }
}
