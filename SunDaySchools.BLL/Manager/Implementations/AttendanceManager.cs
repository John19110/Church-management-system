using AutoMapper;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Repository.Interfaces;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class AttendanceManager : IAttendanceManager
    {
        private readonly IAttendanceRepository _attendanceRepository;
        private readonly IMapper _mapper;

        public AttendanceManager(IAttendanceRepository attendanceRepository, IMapper mapper)
        {
            _attendanceRepository = attendanceRepository ?? throw new ArgumentNullException(nameof(attendanceRepository));
            _mapper = mapper ?? throw new ArgumentNullException(nameof(mapper));
        }

        // ✅ Make it async so you don't block threads or risk deadlocks
        public async Task TakeAttendanceAsync(AttendanceSessionAddDTO session)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));


            session.Records ??= new List<AttendanceRecordAddDTO>();

          
            // Map DTO -> Entity

            var entity = _mapper.Map<AttendanceSession>(session);

            // ✅ Actually save
            await _attendanceRepository.Take(entity);
        }

        // ✅ Make it async
        public async Task EditAttendanceAsync(AttendanceSessionUpdateDTO sessionDto)
        {
            if (sessionDto == null) throw new ArgumentNullException(nameof(sessionDto));
            if (sessionDto.Id <= 0) throw new ArgumentException("Session must have a valid Id to edit.", nameof(sessionDto));

            // Load the existing entity from database WITH records
            var existingSession = await _attendanceRepository.Get(sessionDto.Id);
            if (existingSession == null)
                throw new InvalidOperationException($"Attendance session with Id {sessionDto.Id} not found.");

            // Ensure records list exists
            sessionDto.Records ??= new List<AttendanceRecordUpdateDTO>();

            // MANUALLY update properties (or use mapper with custom logic)
            existingSession.ClassroomId = sessionDto.ClassroomId;
            existingSession.TakenByServantId = sessionDto.TakenByServantId;
            existingSession.Notes = sessionDto.Notes;
            // Don't update CreatedAtUtc - keep original

            // Handle records - complex logic here
            await UpdateAttendanceRecords(existingSession, sessionDto.Records);

            // Save changes
            await _attendanceRepository.Edit(existingSession);
        }

        private async Task UpdateAttendanceRecords(AttendanceSession existingSession, List<AttendanceRecordUpdateDTO> recordDtos)
        {
            // Get existing record IDs
            var existingRecordIds = existingSession.Records.Select(r => r.Id).ToList();
            var incomingRecordIds = recordDtos.Where(r => r.Id > 0).Select(r => r.Id).ToList();

            // Remove records that are no longer present
            var recordsToRemove = existingSession.Records
                .Where(r => !incomingRecordIds.Contains(r.Id))
                .ToList();

            foreach (var record in recordsToRemove)
            {
                existingSession.Records.Remove(record);
            }

            // Update or add records
            foreach (var recordDto in recordDtos)
            {
                if (recordDto.Id > 0 && existingRecordIds.Contains(recordDto.Id))
                {
                    // Update existing record
                    var existingRecord = existingSession.Records
                        .FirstOrDefault(r => r.Id == recordDto.Id);

                    if (existingRecord != null)
                    {
                        existingRecord.MemberId = recordDto.MemberId;
                        existingRecord.MadeHomeWork = recordDto.MadeHomeWork;
                        existingRecord.HasTools = recordDto.HasTools;
                        existingRecord.Status = recordDto.Status;
                        existingRecord.Note = recordDto.Note;
                        existingRecord.UpdatedAt = DateTime.UtcNow;
                    }
                }
                else
                {
                    // Add new record
                    var newRecord = new AttendanceRecord
                    {
                        MemberId = recordDto.MemberId,
                        MadeHomeWork = recordDto.MadeHomeWork,
                        HasTools = recordDto.HasTools,
                        Status = recordDto.Status,
                        Note = recordDto.Note,
                        AttendanceSessionId = existingSession.Id,
                        UpdatedAt = DateTime.Now
                    };
                    existingSession.Records.Add(newRecord);
                }
            }
        }
        // ✅ Make it async
        public async Task<AttendanceSessionReadDTO?> GetAttendanceAsync(int sessionId)
        {
            var result = await _attendanceRepository.Get(sessionId);

            if (result == null) return null;

            // NOTE: Records will be empty unless repository loads them:
            // _context.AttendanceSessions.Include(s => s.Records)...
            return _mapper.Map<AttendanceSessionReadDTO>(result);
        }
    }
}