using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.BLL.Abstractions;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Exceptions;         
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.BLL.Services.Auth.Interfaces;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.IdentityModel.Tokens.Jwt;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class AccountManager : IAccountManager
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ITokenService _tokenService;
        private readonly IServantRepository _servantRepo;
        private readonly IChurchRepository _churchRepo;
        private readonly IAdminRepository _adminRepo;
        private readonly IMeetingRepository _meetingRepo;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IFileManager _fileManager;
        private readonly IAuthOtpManager _authOtpManager;


        public AccountManager(UserManager<ApplicationUser>usermagaer, ITokenService tokenService,
            IServantRepository servantRepo, IChurchRepository churchRepo, IAdminRepository adminRepo,
            IMeetingRepository meetingRepo, IUnitOfWork unitOfWork,IFileManager fileManager,
            IAuthOtpManager authOtpManager)
        {

            _churchRepo = churchRepo;
            _userManager = usermagaer;
            _tokenService = tokenService;
            _servantRepo = servantRepo;
            _adminRepo = adminRepo;
            _meetingRepo = meetingRepo;
            _unitOfWork = unitOfWork;
            _fileManager = fileManager;
            _authOtpManager = authOtpManager;
        }

        public async Task<AuthFlowResultDto> Login(LoginDTO loginDto)
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

            if (!existingUser.IsPhoneVerified)
                throw new PhoneNotVerifiedException(phoneNumber);

            var check = await _userManager.CheckPasswordAsync(existingUser, loginDto.Password);
            if (!check)
                throw new InvalidCredentialsException();

            var claims = await BuildJwtClaims(existingUser);
            return AuthFlowResultDto.Success(_tokenService.CreateAccessToken(claims));
        }
        public async Task<AuthFlowResultDto> RegisterChurchSuperAdmin(RegisterChurchAdminDTO dto, string webRootPath)
        {
            if (dto == null)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["registerDto"] = new[] { "Registration data cannot be null." }
                });
            }

          

            var errors = new Dictionary<string, string[]>();


            if (dto.Password != dto.ConfirmPassword)
                errors["Name"] = new[] { "Password and confirm doesnt match." };

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
          //  var userName = phoneNumber;

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

            await RunInTransactionAsync(async () =>
            {
                var church = new Church
                {
                    Name = dto.ChurchName.Trim()
                };

                await _churchRepo.AddAsync(church);
                await _unitOfWork.SaveChangesAsync();

                var user = new ApplicationUser
                {
                    UserName = dto.Name,
                    PhoneNumber = phoneNumber,
                    IsApproved = true,
                    IsPhoneVerified = false,
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

                var servant = new Servant
                {
                    ApplicationUserId = user.Id,
                    Name = dto.Name.Trim(),
                    PhoneNumber = phoneNumber,
                    ChurchId = church.Id,
                    BirthDate = dto.BirthDate,
                    JoiningDate = dto.BirthDate
                };

                church.Pastor = servant;

                var (fileName, url) = await _fileManager.SaveImageAsync(
                    dto.Image,
                    webRootPath,
                    "images"
                );

                servant.ImageFileName = fileName;
                servant.ImageUrl = url;
                user.ServantProfile = servant;

                await _servantRepo.AddAsync(servant);
                await _unitOfWork.SaveChangesAsync();
            });

            await _authOtpManager.SendPhoneVerificationAfterRegistrationAsync(phoneNumber);
            return AuthFlowResultDto.RequiresVerification(phoneNumber);
        }
        public async Task<AuthFlowResultDto> RegisterMeetingAdminNewChurch(RegisterMeetingAdminNewChurchDTO registerMeetingAdminDTO,string webRootPath)
        {
            if (registerMeetingAdminDTO == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["registerDto"] = new[] { "Registration data cannot be null." }
                });

                 if (registerMeetingAdminDTO.Password != registerMeetingAdminDTO.ConfirmPassword)
                throw new PassordsMissMatchException();


            var existingUser = await _userManager.Users
                     .FirstOrDefaultAsync(u => u.PhoneNumber == registerMeetingAdminDTO.PhoneNumber);

            if (existingUser != null)
                throw new UserAlreadyExistsException();

            // Check if church already exists 
            var existingChurch = await _churchRepo.GetByNameAsync(registerMeetingAdminDTO.ChurchName);
            if (existingChurch != null)
                throw new ChurchAlreadyExistsException();
           

            var meetingPhone = registerMeetingAdminDTO.PhoneNumber.Trim().Replace(" ", "");

            await RunInTransactionAsync(async () =>
            {
                var church = new Church
                {
                    Name = registerMeetingAdminDTO.ChurchName
                };
                await _churchRepo.AddAsync(church);
                await _unitOfWork.SaveChangesAsync();

                var meeting = new Meeting
                {
                    Name = registerMeetingAdminDTO.MeetingName,
                    ChurchId = church.Id,
                    Weekly_appointment = TimeOnly.FromDateTime(registerMeetingAdminDTO.Weekly_appointment),
                    DayOfWeek = registerMeetingAdminDTO.Weekly_appointment.DayOfWeek.ToString()
                };
                await _meetingRepo.AddAsync(meeting);
                await _unitOfWork.SaveChangesAsync();

                var user = new ApplicationUser
                {
                    UserName = registerMeetingAdminDTO.Name,
                    PhoneNumber = meetingPhone,
                    IsApproved = true,
                    IsPhoneVerified = false,
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

                var roleResult = await _userManager.AddToRoleAsync(user, "Admin");
                if (!roleResult.Succeeded)
                    throw new Exception("Failed to assign Admin role.");

                var servant = new Servant
                {
                    ApplicationUserId = user.Id,
                    Name = registerMeetingAdminDTO.Name,
                    PhoneNumber = registerMeetingAdminDTO.PhoneNumber,
                    BirthDate = registerMeetingAdminDTO.BirthDate,
                    JoiningDate = registerMeetingAdminDTO.JoiningDate,
                    ChurchId = church.Id,
                    MeetingId = meeting.Id
                };

                var (fileName, url) = await _fileManager.SaveImageAsync(
                    registerMeetingAdminDTO.Image,
                    webRootPath,
                    "images"
                );

                servant.ImageFileName = fileName;
                servant.ImageUrl = url;
                user.ServantProfile = servant;
                meeting.LeaderServant = servant;

                await _servantRepo.AddAsync(servant);
                await _unitOfWork.SaveChangesAsync();
            });

            await _authOtpManager.SendPhoneVerificationAfterRegistrationAsync(meetingPhone);
            return AuthFlowResultDto.RequiresVerification(meetingPhone);
        }
    
        public async Task<AuthFlowResultDto> RegisterServant(RegisterServantDTO registerDto, string webRootPath)
        {
            if (registerDto == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["registerDto"] = new[] { "Registration data cannot be null." }
                });

            if (registerDto.Password != registerDto.ConfirmPassword)
                throw new PassordsMissMatchException();

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

            var servantPhone = registerDto.PhoneNumber.Trim().Replace(" ", "");

            await RunInTransactionAsync(async () =>
            {
                var user = new ApplicationUser
                {
                    UserName = registerDto.Name,
                    PhoneNumber = servantPhone,
                    IsApproved = false,
                    IsPhoneVerified = false,
                    ChurchId = registerDto.ChurchId,
                    MeetingId = registerDto.MeetingId
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

                var servant = new Servant
                {
                    ApplicationUserId = user.Id,
                    Name = registerDto.Name,
                    PhoneNumber = registerDto.PhoneNumber,
                    BirthDate = registerDto.BirthDate,
                    JoiningDate = registerDto.BirthDate,
                    ChurchId = registerDto.ChurchId,
                    MeetingId = registerDto.MeetingId
                };

                var (fileName, url) = await _fileManager.SaveImageAsync(
                    registerDto.Image,
                    webRootPath,
                    "images"
                );

                servant.ImageFileName = fileName;
                servant.ImageUrl = url;
                user.ServantProfile = servant;

                await _servantRepo.AddAsync(servant);
                await _unitOfWork.SaveChangesAsync();
            });

            await _authOtpManager.SendPhoneVerificationAfterRegistrationAsync(servantPhone);
            return AuthFlowResultDto.RequiresVerification(servantPhone);
        }
        /// <summary>
        /// Users with <c>Admin</c>, <c>Servant</c>, or <c>SuperAdmin</c> must have a <c>Servants</c> row linked by <see cref="Servant.ApplicationUserId"/>.
        /// </summary>
        //private async Task EnsurePrivilegedRolesHaveServantProfileAsync(ApplicationUser user, IList<string> roles)
        //{
        //    var needsServantRow = roles.Any(static r =>
        //        string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase) ||
        //        string.Equals(r, "Servant", StringComparison.OrdinalIgnoreCase) ||
        //        string.Equals(r, "SuperAdmin", StringComparison.OrdinalIgnoreCase));

        //    if (!needsServantRow)
        //        return;

        //    var hasProfile = await _servantRepo.HasServantProfileLinkedAsync(user.Id);
        //    if (!hasProfile)
        //        throw new ProfileNotCompletedException();
        //}




        //private static string ResolveScopeFromRoles(IList<string> roles)
        //{
        //    // Role precedence: SuperAdmin > Admin > Servant
        //    if (roles.Any(static r => string.Equals(r, "SuperAdmin", StringComparison.OrdinalIgnoreCase)))
        //        return "Church";

        //    if (roles.Any(static r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase)))
        //        return "Meeting";

        //    return "Classroom";
        //}

        //private string ResolveScope(ApplicationUser user)
        //{
        //    // Highest scope first
        //    if (user.MeetingId.HasValue)
        //    {
        //        // If servant has classrooms → classroom scope
        //        if (user.ServantProfile?.ClassroomServants?.Any() == true)
        //            return "Classroom";

        //        return "Meeting";
        //    }

        //    return "Church";
        //}

        private async Task RunInTransactionAsync(Func<Task> work)
        {
            await _unitOfWork.BeginTransactionAsync();
            try
            {
                await work();
                await _unitOfWork.CommitAsync();
            }
            catch
            {
                await _unitOfWork.RollbackAsync();
                throw;
            }
        }

        private async Task<List<TokenClaimDescriptor>> BuildJwtClaims(ApplicationUser user)
        {
            var claims = new List<TokenClaimDescriptor>
            {
                new() { Type = JwtRegisteredClaimNames.Sub, Value = user.Id },
                new() { Type = ClaimTypes.Name, Value = user.ServantProfile?.Name ?? string.Empty },
                new() { Type = ClaimTypes.MobilePhone, Value = user.PhoneNumber ?? string.Empty },
                new() { Type = "ChurchId", Value = user.ChurchId?.ToString() ?? string.Empty },
            };

            if (user.MeetingId.HasValue)
                claims.Add(new TokenClaimDescriptor { Type = "MeetingId", Value = user.MeetingId.Value.ToString() });

            if (user.ServantProfile?.ClassroomServants?.Any() == true)
            {
                var classroomIds = user.ServantProfile.ClassroomServants
                    .Select(x => x.ClassroomId)
                    .Distinct();
                claims.Add(new TokenClaimDescriptor
                {
                    Type = "ClassroomIds",
                    Value = string.Join(",", classroomIds)
                });
            }

            var roles = await _userManager.GetRolesAsync(user);
            foreach (var role in roles)
                claims.Add(new TokenClaimDescriptor { Type = ClaimTypes.Role, Value = role });

            return claims;
        }
    }
}
