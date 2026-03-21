using AutoMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Repository.Implementations;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using SunDaySchools.BLL.DTOS.Meeting;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class SuperAdminManager: ISuperAdminManager
    {

        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly UserManager<ApplicationUser> _userManager;


        public SuperAdminManager(IHttpContextAccessor httpContextAccessor,UserManager<ApplicationUser> usermanager)
        {

            _httpContextAccessor = httpContextAccessor;
            _userManager = usermanager; 
        }


        public async Task<List<PendingServantDTO>> GetPendingAdmins()
        {
            var claim = _httpContextAccessor.HttpContext?.User?.FindFirst("ChurchId");

            if (claim == null)
                throw new UnauthorizedAccessException("ChurchId claim is missing");

            var churchId = int.Parse(claim.Value);

            var users = await _userManager.Users
                                        .Where(u => !u.IsApproved && u.ChurchId == churchId)
                                        .ToListAsync();

            var result = new List<PendingServantDTO>();

            foreach (var user in users)
            {
                if (await _userManager.IsInRoleAsync(user, "Admin"))
                {
                    result.Add(new PendingServantDTO
                    {
                        Id = user.Id,
                        Name = user.UserName,
                        PhoneNumber = user.PhoneNumber
                    });
                }
            }

            return result;
        }
    }
}
