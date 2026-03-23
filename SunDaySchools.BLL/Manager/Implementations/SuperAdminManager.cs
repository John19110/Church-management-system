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


        public async Task RejectAdmin(string userId)
        {
            var user = await _userManager.FindByIdAsync(userId);

            if (user == null)
                throw new NotFoundException($"User with id {userId} not found.");

            if (user.IsApproved)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["User"] = new[] { "Approved users cannot be rejected." }
                });

            var result = await _userManager.DeleteAsync(user);

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


        public async Task ApproveAdmin(string userId)
        {
            var user = await _userManager.FindByIdAsync(userId);

            if (user == null)
                throw new NotFoundException($"User with id {userId} not found.");

            if (user.IsApproved)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["User"] = new[] { "User is already approved." }
                });

            user.IsApproved = true;

            var result = await _userManager.UpdateAsync(user);

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
