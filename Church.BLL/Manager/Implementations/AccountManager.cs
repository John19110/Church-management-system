using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Church.BLL.Abstractions;
using Church.BLL.DTOS.AccountDtos;
using Church.BLL.Exceptions;         
using Church.BLL.Manager.Interfaces;
using Church.BLL.Services;
using Church.BLL.Services.Auth;
using Church.DAL.Models;
using Church.DAL.Repository.Interfaces;
using Church.Domain;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.IdentityModel.Tokens.Jwt;
using System.Threading.Tasks;

namespace Church.BLL.Manager.Implementations
{
    public class AccountManager : IAccountManager
    {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly ITokenService _tokenService;
        private readonly IServantRepository _servantRepo;
        private readonly IChurchRepository _churchRepo;
        private readonly IAdminRepository _adminRepo;
        private readonly IMeetingRepository _meetingRepo;
        private readonly IClassroomRepository _classroomRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IFileManager _fileManager;
        private readonly IPublicIdResolver _publicIdResolver;
        private readonly IChurchPublicIdService _churchPublicIdService;
        private readonly IMeetingPublicIdService _meetingPublicIdService;


        public AccountManager(UserManager<ApplicationUser>usermagaer, ITokenService tokenService,
            IServantRepository servantRepo, IChurchRepository churchRepo, IAdminRepository adminRepo,
            IMeetingRepository meetingRepo, IClassroomRepository classroomRepository, IUnitOfWork unitOfWork,IFileManager fileManager,
            IPublicIdResolver publicIdResolver,
            IChurchPublicIdService churchPublicIdService,
            IMeetingPublicIdService meetingPublicIdService)
        {

            _churchRepo = churchRepo;
            _userManager = usermagaer;
            _tokenService = tokenService;
            _servantRepo = servantRepo;
            _adminRepo = adminRepo;
            _meetingRepo = meetingRepo;
            _classroomRepository = classroomRepository;
            _unitOfWork = unitOfWork;
            _fileManager = fileManager;
            _publicIdResolver = publicIdResolver;
            _churchPublicIdService = churchPublicIdService;
            _meetingPublicIdService = meetingPublicIdService;
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

            if (!PhoneNumberNormalizer.TryNormalize(loginDto.PhoneNumber, out var phoneNumber))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["PhoneNumber"] = new[] { "Phone number is invalid." }
                });
            }

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

            if (string.IsNullOrWhiteSpace(dto.Name))
                errors["Name"] = new[] { "Name is required." };

            if (string.IsNullOrWhiteSpace(dto.ChurchName))
                errors["ChurchName"] = new[] { "Church name is required." };

            if (string.IsNullOrWhiteSpace(dto.PhoneNumber))
                errors["PhoneNumber"] = new[] { "Phone number is required." };

            if (string.IsNullOrWhiteSpace(dto.Password))
                errors["Password"] = new[] { "Password is required." };

            if (dto.Password != dto.ConfirmPassword)
                errors["ConfirmPassword"] = new[] { "Password and confirm password do not match." };

            if (errors.Any())
                throw new ValidationException(errors);

            var phoneNumber = NormalizeRegistrationPhone(dto.PhoneNumber);

            await EnsurePhoneNumberAvailableAsync(phoneNumber);

            await RunInTransactionAsync(async () =>
            {
                var church = new ChurchModel
                {
                    Name = dto.ChurchName.Trim(),
                    PublicId = await _churchPublicIdService.GenerateUniqueAsync()
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
                    ChurchId = church.Id
                };

                var createUserResult = await _userManager.CreateAsync(user, dto.Password);
                ThrowIfIdentityCreateFailed(createUserResult);

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

            return AuthFlowResultDto.Registered();
        }
        public async Task<AuthFlowResultDto> RegisterMeetingAdminNewChurch(RegisterMeetingAdminNewChurchDTO registerMeetingAdminDTO,string webRootPath)
        {
            if (registerMeetingAdminDTO == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["registerDto"] = new[] { "Registration data cannot be null." }
                });

            var errors = new Dictionary<string, string[]>();

            if (string.IsNullOrWhiteSpace(registerMeetingAdminDTO.Name))
                errors["Name"] = new[] { "Name is required." };

            if (string.IsNullOrWhiteSpace(registerMeetingAdminDTO.PhoneNumber))
                errors["PhoneNumber"] = new[] { "Phone number is required." };

            if (string.IsNullOrWhiteSpace(registerMeetingAdminDTO.Password))
                errors["Password"] = new[] { "Password is required." };

            if (registerMeetingAdminDTO.Password != registerMeetingAdminDTO.ConfirmPassword)
                errors["ConfirmPassword"] = new[] { "Password and confirm password do not match." };

            if (string.IsNullOrWhiteSpace(registerMeetingAdminDTO.ChurchName))
                errors["ChurchName"] = new[] { "Church name is required." };

            if (string.IsNullOrWhiteSpace(registerMeetingAdminDTO.MeetingName))
                errors["MeetingName"] = new[] { "Meeting name is required." };

            if (registerMeetingAdminDTO.Weekly_appointment == default)
                errors["Weekly_appointment"] = new[] { "Weekly appointment is required." };

            if (errors.Any())
                throw new ValidationException(errors);

            var meetingPhone = NormalizeRegistrationPhone(registerMeetingAdminDTO.PhoneNumber);

            await EnsurePhoneNumberAvailableAsync(meetingPhone);

            await RunInTransactionAsync(async () =>
            {
                var church = new ChurchModel
                {
                    Name = registerMeetingAdminDTO.ChurchName.Trim(),
                    PublicId = await _churchPublicIdService.GenerateUniqueAsync()
                };
                await _churchRepo.AddAsync(church);
                await _unitOfWork.SaveChangesAsync();

                var meeting = new Meeting
                {
                    Name = registerMeetingAdminDTO.MeetingName.Trim(),
                    PublicId = await _meetingPublicIdService.GenerateUniqueAsync(church.Id),
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
                    ChurchId = church.Id,
                    MeetingId = meeting.Id
                };

                var result = await _userManager.CreateAsync(user, registerMeetingAdminDTO.Password);
                ThrowIfIdentityCreateFailed(result);

                var roleResult = await _userManager.AddToRoleAsync(user, "Admin");
                if (!roleResult.Succeeded)
                    throw new Exception("Failed to assign Admin role.");

                var servant = new Servant
                {
                    ApplicationUserId = user.Id,
                    Name = registerMeetingAdminDTO.Name,
                    PhoneNumber = meetingPhone,
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
            return AuthFlowResultDto.Registered();
        }
    
        public async Task<AuthFlowResultDto> RegisterServant(RegisterServantDTO registerDto, string webRootPath)
        {
            if (registerDto == null)
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["registerDto"] = new[] { "Registration data cannot be null." }
                });

            var organizationPublicId = registerDto.ChurchPublicId?.Trim() ?? string.Empty;
            if (!PublicIdHelper.IsValidOrganizationPublicId(organizationPublicId))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["ChurchPublicId"] = new[] { "A valid church or meeting identifier is required." }
                });
            }

            var requestedRole = NormalizeRequestedRole(registerDto.RequestedRole);
            var identityRole = MapRequestedRoleToIdentityRole(requestedRole);

            int churchId;
            int? requestedMeetingId = null;
            string? requestedMeetingName = null;

            var church = await _publicIdResolver.GetChurchByPublicIdAsync(organizationPublicId);
            if (church != null)
            {
                churchId = church.Id;

                if (requestedRole != RequestedRoles.ChurchAdmin
                    && string.IsNullOrWhiteSpace(registerDto.RequestedMeetingName))
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["RequestedMeetingName"] = new[] { "Requested meeting name is required." }
                    });
                }

                if (requestedRole == RequestedRoles.Servant
                    && string.IsNullOrWhiteSpace(registerDto.MeetingAdminPhoneNumber))
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["MeetingAdminPhoneNumber"] = new[] { "Meeting admin phone number is required for servants." }
                    });
                }

                requestedMeetingName = string.IsNullOrWhiteSpace(registerDto.RequestedMeetingName)
                    ? null
                    : registerDto.RequestedMeetingName.Trim();
            }
            else
            {
                var meeting = await _publicIdResolver.GetMeetingByPublicIdAsync(organizationPublicId);
                if (meeting == null)
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["ChurchPublicId"] = new[] { "Church or meeting not found." }
                    });
                }

                churchId = meeting.ChurchId;
                requestedMeetingId = meeting.Id;
                requestedMeetingName = string.IsNullOrWhiteSpace(meeting.Name)
                    ? $"Meeting {meeting.Id}"
                    : meeting.Name.Trim();
            }

            return await RegisterServantCoreAsync(
                registerDto,
                churchId,
                meetingId: null,
                requestedMeetingId: requestedMeetingId,
                requestedMeetingName: requestedMeetingName,
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
                requestedMeetingId: null,
                requestedMeetingName: null,
                requestedRole: RequestedRoles.Servant,
                identityRole: "Servant",
                status: RegistrationStatus.Approved,
                webRootPath);

        private async Task<AuthFlowResultDto> RegisterServantCoreAsync(
            RegisterServantDTO registerDto,
            int churchId,
            int? meetingId,
            int? requestedMeetingId,
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
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["ConfirmPassword"] = new[] { "Password and confirm password do not match." }
                });
            }

            if (string.IsNullOrWhiteSpace(registerDto.Name))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Name"] = new[] { "Name is required." }
                });
            }

            if (string.IsNullOrWhiteSpace(registerDto.PhoneNumber))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["PhoneNumber"] = new[] { "Phone number is required." }
                });
            }

            if (string.IsNullOrWhiteSpace(registerDto.Password))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Password"] = new[] { "Password is required." }
                });
            }

            var servantPhone = NormalizeRegistrationPhone(registerDto.PhoneNumber);
            await EnsurePhoneNumberAvailableAsync(servantPhone);

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
                    RequestedMeetingId = requestedMeetingId,
                    RequestedMeetingName = requestedMeetingName,
                    RequestedRole = requestedRole,
                    MeetingAdminPhoneNumber = NormalizeOptionalPhone(
                        registerDto.MeetingAdminPhoneNumber,
                        "MeetingAdminPhoneNumber"),
                    ApprovalDate = isApproved ? DateTime.Now : null,
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
                ThrowIfIdentityCreateFailed(result);

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
                    PhoneNumber = servantPhone,
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
            return AuthFlowResultDto.Registered();
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

        private static string NormalizeRegistrationPhone(string rawPhone)
        {
            if (!PhoneNumberNormalizer.TryNormalize(rawPhone, out var normalized))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["PhoneNumber"] = new[] { "Phone number is invalid." }
                });
            }

            return normalized;
        }

        private static string? NormalizeOptionalPhone(string? rawPhone, string fieldKey)
        {
            if (string.IsNullOrWhiteSpace(rawPhone))
                return null;

            if (!PhoneNumberNormalizer.TryNormalize(rawPhone, out var normalized))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    [fieldKey] = new[] { "Phone number is invalid." }
                });
            }

            return normalized;
        }

        private async Task EnsurePhoneNumberAvailableAsync(string storedPhone)
        {
            if (string.IsNullOrWhiteSpace(storedPhone))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["PhoneNumber"] = new[] { "Phone number is required." }
                });
            }

            if (!PhoneNumberNormalizer.TryNormalize(storedPhone, out var normalized))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["PhoneNumber"] = new[] { "Phone number is invalid." }
                });
            }

            var candidates = PhoneNumberNormalizer.GetLookupCandidates(normalized);
            var exists = await _userManager.Users
                .AnyAsync(u => u.PhoneNumber != null && candidates.Contains(u.PhoneNumber));

            if (exists)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["PhoneNumber"] = new[] { "Phone number already exists." }
                });
            }
        }

        private static void ThrowIfIdentityCreateFailed(IdentityResult result)
        {
            if (result.Succeeded)
                return;

            if (result.Errors.Any(e =>
                    string.Equals(e.Code, "DuplicateUserName", StringComparison.OrdinalIgnoreCase)))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["UserName"] = new[] { "Registration failed due to a username conflict. Please try again." }
                });
            }

            throw new ValidationException(
                result.Errors
                    .GroupBy(e => e.Code)
                    .ToDictionary(
                        g => g.Key,
                        g => g.Select(e => e.Description).ToArray()));
        }

        private async Task<List<TokenClaimDescriptor>> BuildJwtClaims(ApplicationUser user)
        {
            var servantProfile = await _servantRepo.GetProfileByApplicationUserIdAsync(user.Id);

            var claims = new List<TokenClaimDescriptor>
            {
                new() { Type = JwtRegisteredClaimNames.Sub, Value = user.Id },
                new() { Type = ClaimTypes.Name, Value = servantProfile?.Name ?? string.Empty },
                new() { Type = ClaimTypes.MobilePhone, Value = user.PhoneNumber ?? string.Empty },
                new() { Type = "ChurchId", Value = user.ChurchId?.ToString() ?? string.Empty },
            };

            if (user.MeetingId.HasValue)
                claims.Add(new TokenClaimDescriptor { Type = "MeetingId", Value = user.MeetingId.Value.ToString() });

            if (servantProfile != null)
            {
                var classroomIds = await _classroomRepository
                    .GetAccessibleClassroomIdsForServantAsync(servantProfile.Id);
                if (classroomIds.Count > 0)
                {
                    claims.Add(new TokenClaimDescriptor
                    {
                        Type = "ClassroomIds",
                        Value = string.Join(",", classroomIds)
                    });
                }
            }

            var roles = await _userManager.GetRolesAsync(user);
            foreach (var role in roles)
                claims.Add(new TokenClaimDescriptor { Type = ClaimTypes.Role, Value = role });

            return claims;
        }
    }
}
