using AutoMapper;
using Church.BLL.Abstractions.Caching;
using Church.BLL.DTOS;
using Church.BLL.Exceptions;
using Church.BLL.Manager.Interfaces;
using Church.DAL.Models;
using Church.DAL.Repository.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Church.BLL.Manager.Implementations
{
    public class AttendanceManager : IAttendanceManager
    {
        private readonly IAttendanceRepository _attendanceRepository;
        private readonly IClassroomRepository _classroomRepository;
        private readonly IMeetingRepository _meetingRepository;
        private readonly IAttendanceCriterionRepository _criterionRepository;
        private readonly IMapper _mapper;
        private readonly ICacheService _cache;
        private readonly ICacheKeyBuilder _cacheKeys;
        private readonly ICacheContextAccessor _cacheContext;

        public AttendanceManager(
            IAttendanceRepository attendanceRepository,
            IClassroomRepository classroomRepository,
            IMeetingRepository meetingRepository,
            IAttendanceCriterionRepository criterionRepository,
            IMapper mapper,
            ICacheService cache,
            ICacheKeyBuilder cacheKeys,
            ICacheContextAccessor cacheContext)
        {
            _attendanceRepository = attendanceRepository ?? throw new ArgumentNullException(nameof(attendanceRepository));
            _classroomRepository = classroomRepository ?? throw new ArgumentNullException(nameof(classroomRepository));
            _meetingRepository = meetingRepository ?? throw new ArgumentNullException(nameof(meetingRepository));
            _criterionRepository = criterionRepository ?? throw new ArgumentNullException(nameof(criterionRepository));
            _mapper = mapper ?? throw new ArgumentNullException(nameof(mapper));
            _cache = cache;
            _cacheKeys = cacheKeys;
            _cacheContext = cacheContext;
        }

        public async Task TakeAttendanceAsync(AttendanceSessionAddDTO session)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));

            session.Records ??= new List<AttendanceRecordAddDTO>();

            var (meetingId, classroomId) = await ResolveSessionScopeAsync(
                session.MeetingId,
                session.ClassroomId);

            var meeting = await _meetingRepository.GetByIdAsync(meetingId)
                ?? throw new NotFoundException($"Meeting with id {meetingId} was not found.");

            await _criterionRepository.EnsureDefaultsForMeetingAsync(meeting.Id, meeting.ChurchId);
            var criteria = await _criterionRepository.GetByMeetingAsync(meetingId, includeDeleted: false);
            var activeCriteria = criteria.Where(c => c.IsActive).ToList();

            var entity = _mapper.Map<AttendanceSession>(session);
            entity.MeetingId = meetingId;
            entity.ClassroomId = classroomId;

            for (var i = 0; i < entity.Records.Count; i++)
            {
                var recordDto = session.Records[i];
                ApplyCriterionResults(
                    entity.Records[i],
                    recordDto.CriterionResults,
                    recordDto.HasTools,
                    recordDto.MadeHomeWork,
                    activeCriteria);
            }

            await _attendanceRepository.Take(entity);
            await InvalidateAttendanceCachesAsync();
        }

        public async Task EditAttendanceAsync(AttendanceSessionUpdateDTO sessionDto)
        {
            if (sessionDto == null) throw new ArgumentNullException(nameof(sessionDto));
            if (sessionDto.Id <= 0) throw new ArgumentException("Session must have a valid Id to edit.", nameof(sessionDto));

            var existingSession = await _attendanceRepository.Get(sessionDto.Id);
            if (existingSession == null)
                throw new InvalidOperationException($"Attendance session with Id {sessionDto.Id} not found.");

            sessionDto.Records ??= new List<AttendanceRecordUpdateDTO>();

            var (meetingId, classroomId) = await ResolveSessionScopeAsync(
                sessionDto.MeetingId ?? existingSession.MeetingId,
                sessionDto.ClassroomId ?? existingSession.ClassroomId,
                allowExistingMeetingFallback: true);

            existingSession.MeetingId = meetingId;
            existingSession.ClassroomId = classroomId;
            existingSession.TakenByServantId = sessionDto.TakenByServantId;
            existingSession.Notes = sessionDto.Notes;

            await UpdateAttendanceRecords(existingSession, sessionDto.Records);
            await _attendanceRepository.Edit(existingSession);
            await InvalidateAttendanceCachesAsync();
        }

        private async Task<(int MeetingId, int? ClassroomId)> ResolveSessionScopeAsync(
            int? meetingId,
            int? classroomId,
            bool allowExistingMeetingFallback = false)
        {
            if (classroomId is > 0)
            {
                var classroom = await _classroomRepository.GetByIdAsync(classroomId.Value);
                if (classroom == null)
                    throw new NotFoundException($"Classroom with id {classroomId.Value} was not found.");

                if (classroom.MeetingId is null or <= 0)
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["ClassroomId"] = new[] { "This classroom is not assigned to a meeting." }
                    });
                }

                var meetingFromClassroom = await _meetingRepository.GetByIdAsync(classroom.MeetingId.Value);
                if (meetingFromClassroom == null)
                    throw new NotFoundException($"Meeting with id {classroom.MeetingId.Value} was not found.");

                if (!meetingFromClassroom.HasClassrooms)
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["ClassroomId"] = new[]
                        {
                            "This meeting does not use classrooms. Take attendance at the meeting level."
                        }
                    });
                }

                if (meetingId is > 0 && meetingId.Value != classroom.MeetingId.Value)
                {
                    throw new ValidationException(new Dictionary<string, string[]>
                    {
                        ["MeetingId"] = new[]
                        {
                            "The selected classroom does not belong to the specified meeting."
                        }
                    });
                }

                return (classroom.MeetingId.Value, classroom.Id);
            }

            var resolvedMeetingId = meetingId ?? 0;
            if (resolvedMeetingId <= 0 && !allowExistingMeetingFallback)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["MeetingId"] = new[]
                    {
                        "MeetingId is required when ClassroomId is not provided."
                    }
                });
            }

            if (resolvedMeetingId <= 0)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["MeetingId"] = new[] { "MeetingId must be a positive integer." }
                });
            }

            var meeting = await _meetingRepository.GetByIdAsync(resolvedMeetingId);
            if (meeting == null)
                throw new NotFoundException($"Meeting with id {resolvedMeetingId} was not found.");

            if (meeting.HasClassrooms)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["ClassroomId"] = new[]
                    {
                        "This meeting uses classrooms. Provide ClassroomId when taking attendance."
                    }
                });
            }

            return (meeting.Id, null);
        }

        private void ApplyCriterionResults(
            AttendanceRecord record,
            List<Church.BLL.DTOS.AttendanceCriteria.AttendanceCriterionResultAddDTO>? incoming,
            bool legacyHasTools,
            bool legacyMadeHomework,
            List<AttendanceCriterion> activeCriteria)
        {
            incoming ??= new List<Church.BLL.DTOS.AttendanceCriteria.AttendanceCriterionResultAddDTO>();
            record.CriterionResults ??= new List<AttendanceCriterionResult>();
            record.CriterionResults.Clear();

            var byId = activeCriteria.ToDictionary(c => c.Id);
            var seen = new HashSet<int>();

            if (incoming.Count > 0)
            {
                foreach (var item in incoming)
                {
                    if (!byId.TryGetValue(item.CriterionId, out var criterion))
                    {
                        throw new ValidationException(new Dictionary<string, string[]>
                        {
                            ["CriterionResults"] = new[]
                            {
                                $"Criterion id {item.CriterionId} is not an active criterion for this meeting."
                            }
                        });
                    }

                    if (!seen.Add(item.CriterionId))
                    {
                        throw new ValidationException(new Dictionary<string, string[]>
                        {
                            ["CriterionResults"] = new[]
                            {
                                $"Duplicate result for criterion id {item.CriterionId}."
                            }
                        });
                    }

                    record.CriterionResults.Add(new AttendanceCriterionResult
                    {
                        AttendanceCriterionId = criterion.Id,
                        BoolValue = item.Value,
                        DisplayNameSnapshot = criterion.DisplayName,
                        DisplayNameArSnapshot = criterion.DisplayNameAr
                    });
                }
            }
            else
            {
                // Legacy clients: map MadeHomeWork / HasTools into seeded criteria.
                foreach (var criterion in activeCriteria)
                {
                    bool? value = null;
                    if (criterion.Name.Equals(
                            AttendanceCriterionNames.HasTools,
                            StringComparison.OrdinalIgnoreCase))
                        value = legacyHasTools;
                    else if (criterion.Name.Equals(
                                 AttendanceCriterionNames.DidHomework,
                                 StringComparison.OrdinalIgnoreCase))
                        value = legacyMadeHomework;

                    if (value == null) continue;

                    record.CriterionResults.Add(new AttendanceCriterionResult
                    {
                        AttendanceCriterionId = criterion.Id,
                        BoolValue = value,
                        DisplayNameSnapshot = criterion.DisplayName,
                        DisplayNameArSnapshot = criterion.DisplayNameAr
                    });
                }
            }

            // Dual-write legacy columns for transition / older readers.
            record.HasTools = record.CriterionResults
                .FirstOrDefault(r => byId.TryGetValue(r.AttendanceCriterionId, out var c)
                                     && c.Name.Equals(
                                         AttendanceCriterionNames.HasTools,
                                         StringComparison.OrdinalIgnoreCase))
                ?.BoolValue
                ?? legacyHasTools;

            record.MadeHomeWork = record.CriterionResults
                .FirstOrDefault(r => byId.TryGetValue(r.AttendanceCriterionId, out var c)
                                     && c.Name.Equals(
                                         AttendanceCriterionNames.DidHomework,
                                         StringComparison.OrdinalIgnoreCase))
                ?.BoolValue
                ?? legacyMadeHomework;
        }

        private async Task UpdateAttendanceRecords(AttendanceSession existingSession, List<AttendanceRecordUpdateDTO> recordDtos)
        {
            var meeting = await _meetingRepository.GetByIdAsync(existingSession.MeetingId)
                ?? throw new NotFoundException($"Meeting with id {existingSession.MeetingId} was not found.");

            await _criterionRepository.EnsureDefaultsForMeetingAsync(meeting.Id, meeting.ChurchId);
            var activeCriteria = (await _criterionRepository.GetByMeetingAsync(meeting.Id, includeDeleted: false))
                .Where(c => c.IsActive)
                .ToList();

            var existingRecordIds = existingSession.Records.Select(r => r.Id).ToList();
            var incomingRecordIds = recordDtos.Where(r => r.Id > 0).Select(r => r.Id).ToList();

            var recordsToRemove = existingSession.Records
                .Where(r => !incomingRecordIds.Contains(r.Id))
                .ToList();

            foreach (var record in recordsToRemove)
            {
                existingSession.Records.Remove(record);
            }

            foreach (var recordDto in recordDtos)
            {
                if (recordDto.Id > 0 && existingRecordIds.Contains(recordDto.Id))
                {
                    var existingRecord = existingSession.Records
                        .FirstOrDefault(r => r.Id == recordDto.Id);

                    if (existingRecord != null)
                    {
                        existingRecord.MemberId = recordDto.MemberId;
                        existingRecord.Status = recordDto.Status;
                        existingRecord.Note = recordDto.Note;
                        existingRecord.UpdatedAt = DateTime.UtcNow;
                        ApplyCriterionResults(
                            existingRecord,
                            recordDto.CriterionResults,
                            recordDto.HasTools,
                            recordDto.MadeHomeWork,
                            activeCriteria);
                    }
                }
                else
                {
                    var newRecord = new AttendanceRecord
                    {
                        MemberId = recordDto.MemberId,
                        Status = recordDto.Status,
                        Note = recordDto.Note,
                        AttendanceSessionId = existingSession.Id,
                        UpdatedAt = DateTime.Now
                    };
                    ApplyCriterionResults(
                        newRecord,
                        recordDto.CriterionResults,
                        recordDto.HasTools,
                        recordDto.MadeHomeWork,
                        activeCriteria);
                    existingSession.Records.Add(newRecord);
                }
            }
        }

        public async Task<AttendanceSessionReadDTO?> GetAttendanceAsync(int sessionId)
        {
            var ctx = _cacheContext.TryGet();
            if (ctx is null)
            {
                var raw = await _attendanceRepository.Get(sessionId);
                return raw == null ? null : _mapper.Map<AttendanceSessionReadDTO>(raw);
            }

            var key = _cacheKeys.Tenant("attendance", ("sessionId", sessionId));
            return await _cache.GetOrCreateAsync(
                key,
                new CacheEntryOptions(CacheTtls.Statistics),
                ctx,
                async _ =>
                {
                    var raw = await _attendanceRepository.Get(sessionId);
                    return raw == null ? null : _mapper.Map<AttendanceSessionReadDTO>(raw);
                });
        }

        public async Task<List<AttendanceSessionSummaryDTO>> GetHistoryByClassroomAsync(int classroomId)
        {
            if (classroomId <= 0) throw new ArgumentException("ClassroomId must be a positive integer.", nameof(classroomId));

            var ctx = _cacheContext.TryGet();
            if (ctx is null)
            {
                var raw = await _attendanceRepository.GetByClassroom(classroomId);
                return raw.Select(s => _mapper.Map<AttendanceSessionSummaryDTO>(s)).ToList();
            }

            var key = _cacheKeys.Tenant("statistics", ("attendanceHistoryClassroomId", classroomId));
            return await _cache.GetOrCreateAsync(
                key,
                new CacheEntryOptions(CacheTtls.Statistics),
                ctx,
                async _ =>
                {
                    var raw = await _attendanceRepository.GetByClassroom(classroomId);
                    return raw.Select(s => _mapper.Map<AttendanceSessionSummaryDTO>(s)).ToList();
                });
        }

        public async Task<List<AttendanceSessionSummaryDTO>> GetHistoryByMeetingAsync(int meetingId)
        {
            if (meetingId <= 0) throw new ArgumentException("MeetingId must be a positive integer.", nameof(meetingId));

            var ctx = _cacheContext.TryGet();
            if (ctx is null)
            {
                var raw = await _attendanceRepository.GetByMeeting(meetingId);
                return raw.Select(s => _mapper.Map<AttendanceSessionSummaryDTO>(s)).ToList();
            }

            var key = _cacheKeys.Tenant("statistics", ("attendanceHistoryMeetingId", meetingId));
            return await _cache.GetOrCreateAsync(
                key,
                new CacheEntryOptions(CacheTtls.Statistics),
                ctx,
                async _ =>
                {
                    var raw = await _attendanceRepository.GetByMeeting(meetingId);
                    return raw.Select(s => _mapper.Map<AttendanceSessionSummaryDTO>(s)).ToList();
                });
        }

        private async Task InvalidateAttendanceCachesAsync()
        {
            var ctx = _cacheContext.TryGet();
            if (ctx is not null)
            {
                await _cache.RemoveTenantSegmentAsync("statistics", ctx);
                await _cache.RemoveTenantSegmentAsync("attendance", ctx);
                await _cache.RemoveTenantSegmentAsync("dashboard", ctx);
            }
        }
    }
}
