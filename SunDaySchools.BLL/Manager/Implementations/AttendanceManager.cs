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

            foreach (AttendanceRecordAddDTO c in session.Records)
            {
                c.ChildId

            }

            // Map DTO -> Entity
            var entity = _mapper.Map<AttendanceSession>(session);

            // ✅ Actually save
            await _attendanceRepository.TakeAttendance(entity);
        }

        // ✅ Make it async
        public async Task EditAttendanceAsync(AttendanceSessionUpdateDTO session)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));
            if (session.Id <= 0) throw new ArgumentException("Session must have a valid Id to edit.", nameof(session));

            // Ensure exists (optional but good)
            var existing = await _attendanceRepository.GetAttendance(session.Id);
            if (existing == null)
                throw new InvalidOperationException($"Attendance session with Id {session.Id} not found.");

            // Ensure records list exists (DTO-side)
            session.Records ??= new List<AttendanceRecordUpdateDTO>();

            // Map DTO -> Entity
            var entity = _mapper.Map<AttendanceSession>(session);

            // ✅ Actually save update
            await _attendanceRepository.EditAttendance(entity);
        }

        // ✅ Make it async
        public async Task<AttendanceSessionReadDTO?> GetAttendanceAsync(int sessionId)
        {
            var result = await _attendanceRepository.GetAttendance(sessionId);

            if (result == null) return null;

            // NOTE: Records will be empty unless repository loads them:
            // _context.AttendanceSessions.Include(s => s.Records)...
            return _mapper.Map<AttendanceSessionReadDTO>(result);
        }
    }
}