using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Exceptions;          // <-- Add this
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Models;
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
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IConfiguration _configuration;
        private readonly IServantRepository _servantRepo;
        private readonly IChurchRepository _churchRepo;
        private readonly IAdminRepository _adminRepo;
        private readonly IMeetingRepository _meetingRepo;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IFileManager _fileManager;


        public AccountManager(UserManager<ApplicationUser>usermagaer, IConfiguration configuration,
            IServantRepository servantRepo, IChurchRepository churchRepo, IAdminRepository adminRepo,
            IMeetingRepository meetingRepo, IUnitOfWork unitOfWork,IFileManager fileManager)
        {

            _churchRepo = churchRepo;
            _userManager = usermagaer;
            _configuration = configuration;
            _servantRepo = servantRepo;
            _adminRepo = adminRepo;
            _meetingRepo = meetingRepo;
            _unitOfWork = unitOfWork;
            _fileManager = fileManager;
        }

        public async Task<string> Login(LoginDTO loginDto)
        {
            if (loginDto == null)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["loginDto"] = new[] { "Login data cannot be null." }
                });
            }

            var errors = new Dictionary<string, string[]>();

            if (string.IsNullOrWhiteSpace(loginDto.PhoneNumber))
                errors["PhoneNumber"] = new[] { "Phone number is required." };

            if (string.IsNullOrWhiteSpace(loginDto.Password))
                errors["Password"] = new[] { "Password is required." };

            if (errors.Any())
                throw new ValidationException(errors);

            var phoneNumber = loginDto.PhoneNumber.Trim().Replace(" ", "");

            var existingUser = await _userManager.Users
                .FirstOrDefaultAsync(u => u.PhoneNumber == phoneNumber);

            if (existingUser == null)
                throw new InvalidCredentialsException();

            if (!existingUser.IsApproved)
                throw new AccountNotApprovedException();

            var check = await _userManager.CheckPasswordAsync(existingUser, loginDto.Password);
            if (!check)
                throw new InvalidCredentialsException();

            var claims = await BuildJwtClaims(existingUser);
            return GenerateToken(claims);
        }
        public async Task<string> RegisterChurchSuperAdmin(RegisterChurchAdminDTO dto, string webRootPath)
        {
            if (dto == null)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["registerDto"] = new[] { "Registration data cannot be null." }
                });
            }

            var errors = new Dictionary<string, string[]>();

            if (string.IsNullOrWhiteSpace(dto.Name))
                errors["Name"] = new[] { "Name is required." };

            if (string.IsNullOrWhiteSpace(dto.ChurchName))
                errors["ChurchName"] = new[] { "Church name is required." };

            if (string.IsNullOrWhiteSpace(dto.PhoneNumber))
                errors["PhoneNumber"] = new[] { "Phone number is required." };

            if (string.IsNullOrWhiteSpace(dto.Password))
                errors["Password"] = new[] { "Password is required." };

            if (errors.Any())
                throw new ValidationException(errors);

            var phoneNumber = dto.PhoneNumber.Trim().Replace(" ", "");
            var userName = phoneNumber;

            var existingUser = await _userManager.Users
                .FirstOrDefaultAsync(u => u.PhoneNumber == phoneNumber);

            if (existingUser != null)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["PhoneNumber"] = new[] { "Phone number already exists." }
                });
            }

            var existingChurch = await _churchRepo.GetByNameAsync(dto.ChurchName.Trim());
            if (existingChurch != null)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["ChurchName"] = new[] { "A church with this name already exists." }
                });
            }

            await _unitOfWork.BeginTransactionAsync();

            try
            {
                // ✅ Create Church
                var church = new Church
                {
                    Name = dto.ChurchName.Trim()
                };

                await _churchRepo.AddAsync(church);
                await _unitOfWork.SaveChangesAsync();

                // ✅ Create User
                var user = new ApplicationUser
                {
                    UserName = userName,
                    PhoneNumber = phoneNumber,
                    IsApproved = true,
                    ChurchId = church.Id
                };

                var createUserResult = await _userManager.CreateAsync(user, dto.Password);
                if (!createUserResult.Succeeded)
                {
                    throw new ValidationException(
                        createUserResult.Errors
                            .GroupBy(e => e.Code)
                            .ToDictionary(
                                g => g.Key,
                                g => g.Select(e => e.Description).ToArray()
                            )
                    );
                }

                var addToRoleResult = await _userManager.AddToRoleAsync(user, "SuperAdmin");
                if (!addToRoleResult.Succeeded)
                {
                    throw new ValidationException(
                        addToRoleResult.Errors
                            .GroupBy(e => e.Code)
                            .ToDictionary(
                                g => g.Key,
                                g => g.Select(e => e.Description).ToArray()
                            )
                    );
                }

                // ✅ Create Servant
                var servant = new Servant
                {
                    ApplicationUserId = user.Id,
                    Name = dto.Name.Trim(),
                    PhoneNumber = phoneNumber,
                    ChurchId = church.Id,
                    BirthDate = dto.BirthDate,
                    JoiningDate = dto.BirthDate

                };

                // 🔥 Save Image
                var (fileName, url) = await _fileManager.SaveImageAsync(
                    dto.Image,
                    webRootPath,
                    "images"
                );

                servant.ImageFileName = fileName;
                servant.ImageUrl = url;

                // ✅ Link User ↔ Servant
                user.ServantProfile = servant;

                await _adminRepo.AddServantAsync(servant);
                await _unitOfWork.SaveChangesAsync();

                await _unitOfWork.CommitAsync();

                var claims = await BuildJwtClaims(user);
                return GenerateToken(claims);
            }
            catch
            {
                await _unitOfWork.RollbackAsync();
                throw;
            }
        }
        public async Task<string> RegisterMeetingAdminNewChurch(RegisterMeetingAdminNewChurchDTO registerMeetingAdminDTO,string webRootPath)
        {
            if (registerMeetingAdminDTO == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["registerDto"] = new[] { "Registration data cannot be null." }
                });

            // Check if user already exists
            var existingUser = await _userManager.FindByNameAsync(registerMeetingAdminDTO.Name);
            if (existingUser != null)
                throw new UserAlreadyExistsException();

            // Check if church already exists 
            var existingChurch = await _churchRepo.GetByNameAsync(registerMeetingAdminDTO.ChurchName);
            if (existingChurch != null)
                throw new ChurchAlreadyExistsException();

            // Check if meeting already exists
            var existingMeeting = await _meetingRepo.GetByNameAsync(registerMeetingAdminDTO.MeetingName);
            if (existingMeeting != null)
                throw new MeetingAlreadyExistsException();

            await _unitOfWork.BeginTransactionAsync();

            try
            {

                // Create the church
                var church = new Church
            {
                Name = registerMeetingAdminDTO.ChurchName
            };
            await _churchRepo.AddAsync(church);
            await _unitOfWork.SaveChangesAsync();


                // Create the meeting
                var meeting = new Meeting
            {
                Name = registerMeetingAdminDTO.MeetingName,
                ChurchId = church.Id
            };
            await _meetingRepo.AddAsync(meeting);
            await _unitOfWork.SaveChangesAsync();



                // Create the user
                var user = new ApplicationUser
            {
                UserName = registerMeetingAdminDTO.Name,
                PhoneNumber = registerMeetingAdminDTO.PhoneNumber,
                IsApproved = true,
                ChurchId = church.Id,
                MeetingId = meeting.Id
            };

            var result = await _userManager.CreateAsync(user, registerMeetingAdminDTO.Password);
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

            await _userManager.AddToRoleAsync(user, "Admin");

            // Create the servant
            var servant = new Servant
            {
                ApplicationUserId = user.Id,
                Name = registerMeetingAdminDTO.Name,
                PhoneNumber = registerMeetingAdminDTO.PhoneNumber,
                ChurchId = church.Id
            };

            // 🔥 Save Image
            var (fileName, url) = await _fileManager.SaveImageAsync(
                registerMeetingAdminDTO.Image,
                webRootPath,
                "images"
            );

            servant.ImageFileName = fileName;
            servant.ImageUrl = url;

            // Link User ↔ Servant
            user.ServantProfile = servant;

            await _adminRepo.AddServantAsync(servant);
            await _unitOfWork.SaveChangesAsync();

                await _unitOfWork.CommitAsync();

                var claims = await BuildJwtClaims(user);
                return GenerateToken(claims);

            }
            catch
            {
                await _unitOfWork.RollbackAsync();
                throw;
            }
        }
        //public async Task<string> RegisterMeetingAdminExistingChurch(RegisterMeetingAdminExistingChurch RegisterDTO)
        //{
        //    if (RegisterDTO == null)
        //        throw new ValidationException(new Dictionary<string, string[]>
        //        {
        //            ["registerDto"] = new[] { "Registration data cannot be null." }
        //        });

        //    // Check if user already exists
        //    var existingUser = await _userManager.FindByNameAsync(RegisterDTO.Name);
        //    if (existingUser != null)
        //        throw new UserAlreadyExistsException();


        //    //Check if church already exists 
        //    var existingChurch = await _churchRepo.GetByIdAsync(RegisterDTO.ChurchId);
        //    if (existingChurch == null)
        //        throw new NotFoundException("Church not found");

        //    var existingMeeting = await _meetingRepo.GetByIdAsync(RegisterDTO.MeetingId);
        //    if (existingMeeting == null)
        //        throw new NotFoundException("Meeting not found");


        //    if (existingMeeting.ChurchId != RegisterDTO.ChurchId)
        //        throw new ValidationException(new Dictionary<string, string[]>
        //        {
        //            ["MeetingId"] = new[] { "The selected meeting does not belong to the selected church." }
        //        });


        //    var user = new ApplicationUser
        //    {
        //        UserName = RegisterDTO.Name,
        //        PhoneNumber = RegisterDTO.PhoneNumber,
        //        IsApproved = false,
        //        ChurchId = RegisterDTO.ChurchId,
        //        MeetingId = RegisterDTO.MeetingId
        //    };

        //    var result = await _userManager.CreateAsync(user, RegisterDTO.Password);
        //    if (!result.Succeeded)
        //    {
        //        // Convert Identity errors to a ValidationException
        //        var errors = result.Errors
        //            .GroupBy(e => e.Code) // or use a custom field name
        //            .ToDictionary(
        //                g => g.Key,
        //                g => g.Select(e => e.Description).ToArray()
        //            );
        //        throw new ValidationException(errors);
        //    }

        //    await _userManager.AddToRoleAsync(user, "Admin");


        //    //Create the servant
        //   var servant = new Servant
        //   {
        //       ApplicationUserId = user.Id,
        //       Name = RegisterDTO.Name,
        //       PhoneNumber = RegisterDTO.PhoneNumber,
        //       ChurchId = RegisterDTO.ChurchId, // 🔥 THIS LINE IS MISSING
        //       MeetingId = RegisterDTO.MeetingId // 🔥 THIS LINE IS MISSING



        //   };
        //    user.ServantProfile = servant;


        //    await _adminRepo.AddServantAsync(servant);

        //    var claims = await BuildJwtClaims(user);
        //    return GenerateToken(claims);
        //}
        public async Task<string> RegisterServant(RegisterServantDTO registerDto, string webRootPath)
        {
            if (registerDto == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["registerDto"] = new[] { "Registration data cannot be null." }
                });

            // Check if user already exists
            var existingUser = await _userManager.FindByNameAsync(registerDto.Name);
            if (existingUser != null)
                throw new UserAlreadyExistsException();

            var church = await _churchRepo.GetByIdAsync(registerDto.ChurchId);
            if (church == null)
                throw new NotFoundException($"Church with id {registerDto.ChurchId} not found.");

            var existingMeeting = await _meetingRepo.GetByIdAsync(registerDto.MeetingId);
            if (existingMeeting == null)
                throw new NotFoundException("Meeting not found");

            if (existingMeeting.ChurchId != registerDto.ChurchId)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["MeetingId"] = new[] { "The selected meeting does not belong to the selected church." }
                });

            await _unitOfWork.BeginTransactionAsync();

            try
            {


                // Create user
                var user = new ApplicationUser
            {
                UserName = registerDto.Name,
                PhoneNumber = registerDto.PhoneNumber,
                ChurchId = registerDto.ChurchId,
                IsApproved = false
            };

            var result = await _userManager.CreateAsync(user, registerDto.Password);

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

            await _userManager.AddToRoleAsync(user, "Servant");
            await _unitOfWork.SaveChangesAsync();


                // Create servant
                var servant = new Servant
            {
                ApplicationUserId = user.Id,
                Name = registerDto.Name,
                PhoneNumber = registerDto.PhoneNumber,
                ChurchId = registerDto.ChurchId
            };

            // 🔥 Save Image using FileManager
            var (fileName, url) = await _fileManager.SaveImageAsync(
                registerDto.Image,
                webRootPath,
                "images"
            );

            servant.ImageFileName = fileName;
            servant.ImageUrl = url;

            // Link navigation property (important)
            user.ServantProfile = servant;

            await _adminRepo.AddServantAsync(servant);
            await _unitOfWork.SaveChangesAsync();

                await _unitOfWork.CommitAsync();

                var claims = await BuildJwtClaims(user);
            return GenerateToken(claims);

        }
            catch
            {
                await _unitOfWork.RollbackAsync();
                throw;
            }

}
        private async Task<List<Claim>> BuildJwtClaims(ApplicationUser user)
        {
            var claims = new List<Claim>
    {
        new Claim(ClaimTypes.NameIdentifier, user.Id),
        new Claim(ClaimTypes.Name, user.UserName ?? ""),
        new Claim("ChurchId", user.ChurchId.ToString())
    };

            if (user.MeetingId.HasValue)
            {
                claims.Add(new Claim("MeetingId", user.MeetingId.Value.ToString()));
            }

            var roles = await _userManager.GetRolesAsync(user);
            foreach (var role in roles)
                claims.Add(new Claim(ClaimTypes.Role, role));

            return claims;
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
