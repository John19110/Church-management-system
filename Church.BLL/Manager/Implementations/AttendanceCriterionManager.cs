using Church.BLL.Abstractions;
using Church.DAL.Abstractions;
using Church.BLL.DTOS.AttendanceCriteria;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;
using Church.DAL.Models;
using Church.DAL.Repository.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace Church.BLL.Manager.Implementations
{
    public class AttendanceCriterionManager : IAttendanceCriterionManager
    {
        private readonly IAttendanceCriterionRepository _repository;
        private readonly IMeetingRepository _meetingRepository;
        private readonly ICurrentUserContext _currentUser;
        private readonly ITenantContext _tenantContext;

        public AttendanceCriterionManager(
            IAttendanceCriterionRepository repository,
            IMeetingRepository meetingRepository,
            ICurrentUserContext currentUser,
            ITenantContext tenantContext)
        {
            _repository = repository;
            _meetingRepository = meetingRepository;
            _currentUser = currentUser;
            _tenantContext = tenantContext;
        }

        public async Task<List<AttendanceCriterionReadDTO>> GetByMeetingAsync(
            int meetingId,
            bool includeInactive = false)
        {
            await EnsureCanAccessMeetingAsync(meetingId);

            var meeting = await _meetingRepository.GetByIdAsync(meetingId)
                ?? throw new NotFoundException($"Meeting with id {meetingId} was not found.");

            await _repository.EnsureDefaultsForMeetingAsync(meeting.Id, meeting.ChurchId);

            var list = await _repository.GetByMeetingAsync(meetingId, includeDeleted: false);
            if (!includeInactive)
                list = list.Where(c => c.IsActive).ToList();

            return list.Select(ToReadDto).ToList();
        }

        public async Task<AttendanceCriterionReadDTO> AddAsync(int meetingId, AttendanceCriterionAddDTO dto)
        {
            EnsureCanManageCriteria();
            var meeting = await EnsureCanAccessMeetingAsync(meetingId);

            var displayName = (dto.DisplayName ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(displayName))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["DisplayName"] = new[] { "Display name is required." }
                });
            }

            var name = string.IsNullOrWhiteSpace(dto.Name)
                ? Slugify(displayName)
                : Slugify(dto.Name!);

            if (string.IsNullOrWhiteSpace(name))
                name = $"criterion_{Guid.NewGuid():N}"[..20];

            var existing = await _repository.GetByMeetingAsync(meetingId, includeDeleted: false);
            if (existing.Any(c => c.Name.Equals(name, StringComparison.OrdinalIgnoreCase)))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Name"] = new[] { "A criterion with this name already exists for the meeting." }
                });
            }

            var sortOrder = dto.SortOrder ?? (existing.Count == 0 ? 0 : existing.Max(c => c.SortOrder) + 1);

            var entity = new AttendanceCriterion
            {
                MeetingId = meeting.Id,
                ChurchId = meeting.ChurchId,
                Name = name,
                DisplayName = displayName,
                DisplayNameAr = string.IsNullOrWhiteSpace(dto.DisplayNameAr)
                    ? null
                    : dto.DisplayNameAr.Trim(),
                DataType = AttendanceCriterionDataType.Boolean,
                IsActive = true,
                IsDeleted = false,
                SortOrder = sortOrder,
                CreatedAt = DateTime.UtcNow
            };

            await _repository.AddAsync(entity);
            return ToReadDto(entity);
        }

        public async Task<AttendanceCriterionReadDTO> UpdateAsync(int id, AttendanceCriterionUpdateDTO dto)
        {
            EnsureCanManageCriteria();

            var entity = await _repository.GetByIdAsync(id)
                ?? throw new NotFoundException($"Attendance criterion with id {id} was not found.");

            if (entity.IsDeleted)
                throw new NotFoundException($"Attendance criterion with id {id} was not found.");

            await EnsureCanAccessMeetingAsync(entity.MeetingId ?? 0);

            var displayName = (dto.DisplayName ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(displayName))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["DisplayName"] = new[] { "Display name is required." }
                });
            }

            entity.DisplayName = displayName;
            entity.DisplayNameAr = string.IsNullOrWhiteSpace(dto.DisplayNameAr)
                ? null
                : dto.DisplayNameAr.Trim();
            entity.IsActive = dto.IsActive;
            entity.SortOrder = dto.SortOrder;
            entity.UpdatedAt = DateTime.UtcNow;

            await _repository.UpdateAsync(entity);
            return ToReadDto(entity);
        }

        public async Task SoftDeleteAsync(int id)
        {
            EnsureCanManageCriteria();

            var entity = await _repository.GetByIdAsync(id)
                ?? throw new NotFoundException($"Attendance criterion with id {id} was not found.");

            if (entity.IsDeleted) return;

            await EnsureCanAccessMeetingAsync(entity.MeetingId ?? 0);

            entity.IsDeleted = true;
            entity.IsActive = false;
            entity.UpdatedAt = DateTime.UtcNow;
            // Keep Name; unique index is filtered to IsDeleted = 0, so a new active
            // criterion can reuse the same friendly name later.

            await _repository.UpdateAsync(entity);
        }

        public async Task ReorderAsync(int meetingId, AttendanceCriterionReorderDTO dto)
        {
            EnsureCanManageCriteria();
            await EnsureCanAccessMeetingAsync(meetingId);

            var criteria = await _repository.GetByMeetingAsync(meetingId, includeDeleted: false);
            var byId = criteria.ToDictionary(c => c.Id);

            if (dto.OrderedIds == null || dto.OrderedIds.Count == 0)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["OrderedIds"] = new[] { "OrderedIds is required." }
                });
            }

            if (dto.OrderedIds.Any(id => !byId.ContainsKey(id)))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["OrderedIds"] = new[] { "One or more criterion ids do not belong to this meeting." }
                });
            }

            for (var i = 0; i < dto.OrderedIds.Count; i++)
            {
                var entity = await _repository.GetByIdAsync(dto.OrderedIds[i]);
                if (entity == null || entity.IsDeleted) continue;
                entity.SortOrder = i;
                entity.UpdatedAt = DateTime.UtcNow;
                await _repository.UpdateAsync(entity);
            }
        }

        private void EnsureCanManageCriteria()
        {
            if (!_currentUser.IsAuthenticated)
                throw new UnauthorizedAccessException("User is not authenticated.");

            // Meeting Admin (role "Admin") or Church Super Admin.
            if (!_currentUser.IsInRole("Admin") && !_currentUser.IsInRole("SuperAdmin"))
                throw new UnauthorizedAccessException(
                    "Only Meeting Admin or Church Super Admin can manage attendance criteria.");
        }

        private async Task<Meeting> EnsureCanAccessMeetingAsync(int meetingId)
        {
            if (meetingId <= 0)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["MeetingId"] = new[] { "Meeting id must be a positive integer." }
                });
            }

            var meeting = await _meetingRepository.GetByIdAsync(meetingId)
                ?? throw new NotFoundException($"Meeting with id {meetingId} was not found.");

            var churchId = _tenantContext.ChurchId
                ?? throw new UnauthorizedAccessException("ChurchId claim is missing.");

            if (meeting.ChurchId != churchId)
                throw new UnauthorizedAccessException("This meeting does not belong to your church.");

            if (_currentUser.IsInRole("SuperAdmin"))
                return meeting;

            if (_currentUser.IsInRole("Admin"))
            {
                var adminMeetingId = _tenantContext.MeetingId;
                if (adminMeetingId == null || adminMeetingId.Value != meeting.Id)
                    throw new UnauthorizedAccessException(
                        "You can only manage attendance criteria for your assigned meeting.");
                return meeting;
            }

            // Servants may read active criteria for take-attendance (GetByMeeting is also used by them).
            if (_currentUser.IsInRole("Servant"))
                return meeting;

            throw new UnauthorizedAccessException("User role is not allowed.");
        }

        private static AttendanceCriterionReadDTO ToReadDto(AttendanceCriterion c) => new()
        {
            Id = c.Id,
            MeetingId = c.MeetingId ?? 0,
            Name = c.Name,
            DisplayName = c.DisplayName,
            DisplayNameAr = c.DisplayNameAr,
            DataType = c.DataType,
            IsActive = c.IsActive,
            SortOrder = c.SortOrder
        };

        private static string Slugify(string input)
        {
            var lower = input.Trim().ToLowerInvariant();
            var slug = Regex.Replace(lower, @"[^a-z0-9]+", "_");
            slug = Regex.Replace(slug, @"_+", "_").Trim('_');
            if (slug.Length > 100) slug = slug[..100];
            return slug;
        }
    }
}
