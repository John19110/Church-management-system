using SunDaySchools.BLL.Abstractions;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;

namespace SunDaySchools.BLL.Application.Servants
{
    public sealed class ServantProfileService : IServantProfileService
    {
        private readonly ICurrentUserContext _currentUser;
        private readonly IServantRepository _servantRepository;

        public ServantProfileService(
            ICurrentUserContext currentUser,
            IServantRepository servantRepository)
        {
            _currentUser = currentUser;
            _servantRepository = servantRepository;
        }

        public async Task<ServantProfileDto> GetForCurrentUserAsync(
            CancellationToken cancellationToken = default)
        {
            var userId = RequireUserId();
            var servant = await _servantRepository.GetProfileByApplicationUserIdAsync(userId, cancellationToken);
            if (servant == null)
                throw new NotFoundException("Servant profile not found for current user.");

            return MapToDto(servant);
        }

        public async Task UpdateForCurrentUserAsync(
            UpdateServantProfileCommand command,
            CancellationToken cancellationToken = default)
        {
            var userId = RequireUserId();
            var servant = await _servantRepository.GetTrackedProfileByApplicationUserIdAsync(
                userId,
                cancellationToken);

            if (servant == null)
                throw new NotFoundException("Servant profile not found for current user.");

            if (command.Name != null)
                servant.Name = command.Name.Trim();
            if (command.PhoneNumber != null)
                servant.PhoneNumber = command.PhoneNumber.Trim();
            if (command.BirthDate.HasValue)
                servant.BirthDate = command.BirthDate;
            if (command.JoiningDate.HasValue)
                servant.JoiningDate = command.JoiningDate;
            if (command.ChurchId.HasValue)
                servant.ChurchId = command.ChurchId;
            if (command.MeetingId.HasValue)
                servant.MeetingId = command.MeetingId;
            if (command.ImageFileName != null)
                servant.ImageFileName = command.ImageFileName;
            if (command.ImageUrl != null)
                servant.ImageUrl = command.ImageUrl;

            if (servant.ApplicationUser != null)
            {
                if (command.PhoneNumber != null)
                    servant.ApplicationUser.PhoneNumber = command.PhoneNumber.Trim();
                if (command.ChurchId.HasValue)
                    servant.ApplicationUser.ChurchId = command.ChurchId;
                if (command.MeetingId.HasValue)
                    servant.ApplicationUser.MeetingId = command.MeetingId;
            }

            if (command.ClassroomIds != null)
                ApplyClassroomAssignments(servant, command.ClassroomIds);

            await _servantRepository.SaveChangesAsync(cancellationToken);
        }

        private static void ApplyClassroomAssignments(Servant servant, List<int> classroomIds)
        {
            var desired = classroomIds
                .Where(id => id > 0)
                .Distinct()
                .ToHashSet();

            servant.ClassroomServants ??= new List<ClassroomServant>();

            var toRemove = servant.ClassroomServants
                .Where(cs => !desired.Contains(cs.ClassroomId))
                .ToList();

            foreach (var cs in toRemove)
                servant.ClassroomServants.Remove(cs);

            var existing = servant.ClassroomServants
                .Select(cs => cs.ClassroomId)
                .ToHashSet();

            foreach (var classroomId in desired)
            {
                if (existing.Contains(classroomId))
                    continue;

                servant.ClassroomServants.Add(new ClassroomServant
                {
                    ServantId = servant.Id,
                    ClassroomId = classroomId
                });
            }
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
                ImageUrl = servant.ImageUrl,
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
    }
}
