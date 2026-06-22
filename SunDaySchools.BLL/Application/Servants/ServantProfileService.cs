using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.BLL.Abstractions;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.UnifiedForms;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Models.CustomFields;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;

namespace SunDaySchools.BLL.Application.Servants
{
    public sealed class ServantProfileService : IServantProfileService
    {
        private readonly ICurrentUserContext _currentUser;
        private readonly IServantRepository _servantRepository;
        private readonly IUnifiedEntityFormManager _unifiedFormManager;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IMeetingRepository _meetingRepository;

        public ServantProfileService(
            ICurrentUserContext currentUser,
            IServantRepository servantRepository,
            IUnifiedEntityFormManager unifiedFormManager,
            UserManager<ApplicationUser> userManager,
            IMeetingRepository meetingRepository)
        {
            _currentUser = currentUser;
            _servantRepository = servantRepository;
            _unifiedFormManager = unifiedFormManager;
            _userManager = userManager;
            _meetingRepository = meetingRepository;
        }

        public async Task<ServantProfileDto> GetForCurrentUserAsync(
            CancellationToken cancellationToken = default)
        {
            var servant = await RequireProfileAsync(cancellationToken);
            var dto = MapToDto(servant);

            if (_currentUser.IsInRole("SuperAdmin") && servant.ChurchId.HasValue)
            {
                var meetings = await _meetingRepository.GetByChurchIdAsync(servant.ChurchId.Value);
                dto.ChurchMeetings = meetings
                    .OrderBy(m => m.Name)
                    .Select(m => new ServantProfileMeetingDto
                    {
                        Id = m.Id,
                        PublicId = m.PublicId,
                        Name = m.Name
                    })
                    .ToList();
            }

            return dto;
        }

        public async Task<EntityFormDataDto> GetFormDataForCurrentUserAsync(
            CancellationToken cancellationToken = default)
        {
            var servant = await RequireProfileAsync(cancellationToken);
            return await _unifiedFormManager.GetFormDataAsync(
                CustomFieldEntityNames.Servant,
                servant.Id);
        }

        public async Task UpdateForCurrentUserAsync(
            UpdateServantProfileCommand command,
            CancellationToken cancellationToken = default)
        {
            var servant = await RequireTrackedProfileAsync(cancellationToken);

            if (command.Name != null)
            {
                var name = command.Name.Trim();
                if (string.IsNullOrEmpty(name))
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["Name"] = new[] { "Name is required." }
                    });
                }
                servant.Name = name;
            }

            if (command.PhoneNumber != null)
            {
                var phone = command.PhoneNumber.Trim().Replace(" ", "");
                if (string.IsNullOrEmpty(phone))
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["PhoneNumber"] = new[] { "Phone number is required." }
                    });
                }

                await EnsurePhoneAvailableAsync(phone, servant.ApplicationUserId, cancellationToken);
                servant.PhoneNumber = phone;
                if (servant.ApplicationUser != null)
                    servant.ApplicationUser.PhoneNumber = phone;
            }

            if (command.BirthDate.HasValue)
                servant.BirthDate = command.BirthDate;
            if (command.JoiningDate.HasValue)
                servant.JoiningDate = command.JoiningDate;
            if (command.ImageFileName != null)
                servant.ImageFileName = command.ImageFileName;
            if (command.ImageUrl != null)
                servant.ImageUrl = command.ImageUrl;

            await _servantRepository.SaveChangesAsync(cancellationToken);
        }

        public async Task SaveFormDataForCurrentUserAsync(
            SaveEntityFormDto dto,
            CancellationToken cancellationToken = default)
        {
            if (dto.Fields == null || dto.Fields.Count == 0)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["fields"] = new[] { "At least one field must be provided." }
                });
            }

            var servant = await RequireTrackedProfileAsync(cancellationToken);
            var filtered = ServantProfileFieldPolicy.FilterEditableFields(dto);

            if (filtered.Fields.Count == 0)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["fields"] = new[] { "No editable profile fields were provided." }
                });
            }

            var phoneField = filtered.Fields
                .FirstOrDefault(f => f.FieldKey.Equals("phoneNumber", StringComparison.OrdinalIgnoreCase));
            if (phoneField?.Value != null)
            {
                var phone = phoneField.Value.Trim().Replace(" ", "");
                if (string.IsNullOrEmpty(phone))
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["phoneNumber"] = new[] { "Phone number is required." }
                    });
                }

                await EnsurePhoneAvailableAsync(phone, servant.ApplicationUserId, cancellationToken);
            }

            await _unifiedFormManager.SaveFormDataAsync(
                CustomFieldEntityNames.Servant,
                servant.Id,
                filtered);

            await SyncApplicationUserFromServantAsync(servant, cancellationToken);
        }

        private async Task SyncApplicationUserFromServantAsync(
            Servant servant,
            CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(servant.ApplicationUserId))
                return;

            var tracked = await _servantRepository.GetTrackedProfileByApplicationUserIdAsync(
                servant.ApplicationUserId,
                cancellationToken);

            if (tracked?.ApplicationUser == null)
                return;

            if (!string.IsNullOrWhiteSpace(tracked.PhoneNumber))
                tracked.ApplicationUser.PhoneNumber = tracked.PhoneNumber.Trim().Replace(" ", "");

            await _servantRepository.SaveChangesAsync(cancellationToken);
        }

        private async Task EnsurePhoneAvailableAsync(
            string normalizedPhone,
            string? currentUserId,
            CancellationToken cancellationToken)
        {
            if (string.IsNullOrWhiteSpace(currentUserId))
                return;

            var taken = await _userManager.Users
                .AsNoTracking()
                .AnyAsync(
                    u => u.PhoneNumber == normalizedPhone && u.Id != currentUserId,
                    cancellationToken);

            if (taken)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["phoneNumber"] = new[] { "This phone number is already in use." }
                });
            }
        }

        private async Task<Servant> RequireProfileAsync(CancellationToken cancellationToken)
        {
            var userId = RequireUserId();
            var servant = await _servantRepository.GetProfileByApplicationUserIdAsync(userId, cancellationToken);
            if (servant == null)
                throw new NotFoundException("Servant profile not found for current user.");

            return servant;
        }

        private async Task<Servant> RequireTrackedProfileAsync(CancellationToken cancellationToken)
        {
            var userId = RequireUserId();
            var servant = await _servantRepository.GetTrackedProfileByApplicationUserIdAsync(
                userId,
                cancellationToken);

            if (servant == null)
                throw new NotFoundException("Servant profile not found for current user.");

            return servant;
        }

        private string RequireUserId()
        {
            if (!_currentUser.IsAuthenticated || string.IsNullOrWhiteSpace(_currentUser.UserId))
                throw new UnauthorizedAccessException("User is not authenticated.");

            return _currentUser.UserId;
        }

        private static ServantProfileDto MapToDto(Servant servant) =>
            new()
            {
                Id = servant.Id,
                Name = servant.Name,
                PhoneNumber = servant.PhoneNumber,
                ImageUrl = ResolveServantImageUrl(servant.ImageUrl, servant.ImageFileName),
                BirthDate = servant.BirthDate,
                JoiningDate = servant.JoiningDate,
                SpiritualBirthDate = null,
                Church = servant.Church == null
                    ? null
                    : new ServantProfileChurchDto
                    {
                        Id = servant.Church.Id,
                        PublicId = servant.Church.PublicId,
                        Name = servant.Church.Name
                    },
                Meeting = servant.Meeting == null
                    ? null
                    : new ServantProfileMeetingDto
                    {
                        Id = servant.Meeting.Id,
                        PublicId = servant.Meeting.PublicId,
                        Name = servant.Meeting.Name
                    },
                Classrooms = servant.ClassroomServants
                    .Select(cs => cs.Classroom)
                    .Where(c => c != null)
                    .Select(c => new ServantProfileClassroomDto
                    {
                        Id = c!.Id,
                        Name = c.Name,
                        AgeOfMembers = c.AgeOfMembers
                    })
                    .ToList()
            };

        private static string? ResolveServantImageUrl(string? imageUrl, string? imageFileName)
        {
            if (!string.IsNullOrWhiteSpace(imageUrl))
                return imageUrl.Trim();

            var fileName = imageFileName?.Trim();
            if (string.IsNullOrEmpty(fileName))
                return null;

            if (fileName.Contains("://", StringComparison.Ordinal))
                return fileName;

            if (fileName.StartsWith('/'))
                return fileName;

            return $"/uploads/{fileName}";
        }
    }
}
