using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.BLL.Abstractions;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Exceptions;         
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.BLL.Services;
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
        private readonly IPublicIdResolver _publicIdResolver;


        public AccountManager(UserManager<ApplicationUser>usermagaer, ITokenService tokenService,
            IServantRepository servantRepo, IChurchRepository churchRepo, IAdminRepository adminRepo,
            IMeetingRepository meetingRepo, IUnitOfWork unitOfWork,IFileManager fileManager,
            IAuthOtpManager authOtpManager, IPublicIdResolver publicIdResolver)
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
            _publicIdResolver = publicIdResolver;
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

            // Approval gate: rejected users are blocked permanently, pending users
            // must wait for the church Super Admin. Approved users continue.
            if (existingUser.RegistrationStatus == RegistrationStatus.Rejected)
                throw new AccountRejectedException();

            if (existingUser.RegistrationStatus == RegistrationStatus.Pending || !existingUser.IsApproved)
                throw new AccountNotApprovedException();

            // TODO: Re-enable WhatsApp/phone verification after verification module is completed.
            //if (!existingUser.IsPhoneVerified)
            //    throw new PhoneNotVerifiedException(phoneNumber);

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
                    RegistrationStatus = RegistrationStatus.Approved,
                    ApprovalDate = DateTime.Now,
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

            // TODO: Re-enable WhatsApp verification after verification module is completed.
            // await _authOtpManager.SendPhoneVerificationAfterRegistrationAsync(phoneNumber);
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
                    RegistrationStatus = RegistrationStatus.Approved,
                    ApprovalDate = DateTime.Now,
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

            // TODO: Re-enable WhatsApp verification after verification module is completed.
            // await _authOtpManager.SendPhoneVerificationAfterRegistrationAsync(meetingPhone);
            return AuthFlowResultDto.RequiresVerification(meetingPhone);
        }
    
        public async Task<AuthFlowResultDto> RegisterServant(RegisterServantDTO registerDto, string webRootPath)
        {
            if (registerDto == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["registerDto"] = new[] { "Registration data cannot be null." }
                });

            if (!PublicIdHelper.IsValidFormat(registerDto.ChurchPublicId))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["ChurchPublicId"] = new[] { "A valid church identifier is required." }
                });
            }

            // Existing-church registration supports three requested roles.
            var requestedRole = NormalizeRequestedRole(registerDto.RequestedRole);
            var identityRole = MapRequestedRoleToIdentityRole(requestedRole);

            // A Church Admin manages the whole church, so no specific meeting is requested.
            if (requestedRole != RequestedRoles.ChurchAdmin
                && string.IsNullOrWhiteSpace(registerDto.RequestedMeetingName))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["RequestedMeetingName"] = new[] { "Requested meeting name is required." }
                });
            }

            // The Meeting Admin phone helps the Super Admin route a servant to the right meeting.
            if (requestedRole == RequestedRoles.Servant
                && string.IsNullOrWhiteSpace(registerDto.MeetingAdminPhoneNumber))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["MeetingAdminPhoneNumber"] = new[] { "Meeting admin phone number is required for servants." }
                });
            }

            var church = await _publicIdResolver.GetChurchByPublicIdAsync(registerDto.ChurchPublicId);
            if (church == null)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["ChurchPublicId"] = new[] { "Church not found." }
                });
            }

            // Existing-church members are created as Pending; the church Super Admin
            // assigns the real meeting/role and approves later.
            return await RegisterServantCoreAsync(
                registerDto,
                church.Id,
                meetingId: null,
                requestedMeetingName: string.IsNullOrWhiteSpace(registerDto.RequestedMeetingName)
                    ? null
                    : registerDto.RequestedMeetingName.Trim(),
                requestedRole: requestedRole,
                identityRole: identityRole,
                status: RegistrationStatus.Pending,
                webRootPath);
        }

        public Task<AuthFlowResultDto> RegisterServantForTenant(
            RegisterServantDTO registerDto,
            int churchId,
            int meetingId,
            string webRootPath) =>
            RegisterServantCoreAsync(
                registerDto,
                churchId,
                meetingId,
                requestedMeetingName: null,
                requestedRole: RequestedRoles.Servant,
                identityRole: "Servant",
                status: RegistrationStatus.Approved,
                webRootPath);

        private async Task<AuthFlowResultDto> RegisterServantCoreAsync(
            RegisterServantDTO registerDto,
            int churchId,
            int? meetingId,
            string? requestedMeetingName,
            string requestedRole,
            string identityRole,
            RegistrationStatus status,
            string webRootPath)
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

            var church = await _churchRepo.GetByIdAsync(churchId);
            if (church == null)
                throw new NotFoundException($"Church with id {churchId} not found.");

            // Meeting is optional for pending registrations; assigned on approval.
            if (meetingId.HasValue)
            {
                var existingMeeting = await _meetingRepo.GetByIdAsync(meetingId.Value);
                if (existingMeeting == null)
                    throw new NotFoundException("Meeting not found");

                if (existingMeeting.ChurchId != churchId)
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["MeetingId"] = new[] { "The selected meeting does not belong to the selected church." }
                    });
            }

            var isApproved = status == RegistrationStatus.Approved;
            var servantPhone = registerDto.PhoneNumber.Trim().Replace(" ", "");

            // Persist the registration photo up front so it is available either for the
            // approved Servant profile or for the pending user's holding fields.
            var (imageFileName, imageUrl) = await _fileManager.SaveImageAsync(
                registerDto.Image,
                webRootPath,
                "images");

            await RunInTransactionAsync(async () =>
            {
                var user = new ApplicationUser
                {
                    UserName = registerDto.Name,
                    PhoneNumber = servantPhone,
                    IsApproved = isApproved,
                    RegistrationStatus = status,
                    RequestedChurchId = churchId,
                    RequestedMeetingName = requestedMeetingName,
                    RequestedRole = requestedRole,
                    MeetingAdminPhoneNumber = string.IsNullOrWhiteSpace(registerDto.MeetingAdminPhoneNumber)
                        ? null
                        : registerDto.MeetingAdminPhoneNumber.Trim().Replace(" ", ""),
                    ApprovalDate = isApproved ? DateTime.Now : null,
                    IsPhoneVerified = false,
                    // Photo/dates are held on the user; they move to the Servant profile on creation.
                    ImageUrl = imageUrl,
                    ImageFileName = imageFileName,
                    BirthDate = registerDto.BirthDate,
                    JoiningDate = registerDto.JoiningDate ?? registerDto.BirthDate,
                    // Pending users are NOT yet attached to a church/meeting; that happens on approval.
                    ChurchId = isApproved ? churchId : null,
                    MeetingId = isApproved ? meetingId : null
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

                // Pending self-registrations are NOT activated yet: no role, no Servant row,
                // no church/meeting assignment. The Super Admin activates everything on approval.
                if (!isApproved)
                {
                    await _unitOfWork.SaveChangesAsync();
                    return;
                }

                await _userManager.AddToRoleAsync(user, identityRole);
                await _unitOfWork.SaveChangesAsync();

                var servant = new Servant
                {
                    ApplicationUserId = user.Id,
                    Name = registerDto.Name,
                    PhoneNumber = registerDto.PhoneNumber,
                    BirthDate = registerDto.BirthDate,
                    JoiningDate = registerDto.JoiningDate ?? registerDto.BirthDate,
                    ChurchId = churchId,
                    MeetingId = meetingId,
                    ImageFileName = imageFileName,
                    ImageUrl = imageUrl
                };

                user.ServantProfile = servant;

                await _servantRepo.AddAsync(servant);
                await _unitOfWork.SaveChangesAsync();
            });

            // TODO: Re-enable WhatsApp verification after verification module is completed.
            // await _authOtpManager.SendPhoneVerificationAfterRegistrationAsync(servantPhone);
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

        /// <summary>Canonical requested-role values stored on the user and exchanged with the client.</summary>
        public static class RequestedRoles
        {
            public const string Servant = "Servant";
            public const string MeetingAdmin = "MeetingAdmin";
            public const string ChurchAdmin = "ChurchAdmin";
        }

        private static string NormalizeRequestedRole(string? requestedRole)
        {
            var value = (requestedRole ?? string.Empty).Trim().Replace(" ", "");

            if (string.Equals(value, "MeetingAdmin", StringComparison.OrdinalIgnoreCase))
                return RequestedRoles.MeetingAdmin;
            if (string.Equals(value, "ChurchAdmin", StringComparison.OrdinalIgnoreCase))
                return RequestedRoles.ChurchAdmin;

            // Default / unknown values fall back to Servant (backward compatible).
            return RequestedRoles.Servant;
        }

        /// <summary>Maps a requested role to an ASP.NET Identity role (only Admin/Servant/SuperAdmin exist).</summary>
        private static string MapRequestedRoleToIdentityRole(string requestedRole) => requestedRole switch
        {
            RequestedRoles.MeetingAdmin => "Admin",
            RequestedRoles.ChurchAdmin => "SuperAdmin",
            _ => "Servant"
        };

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
