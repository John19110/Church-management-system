using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.BLL.DTOS;
using AutoMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class AttendanceManager : IAttendanceManager
    {
        private readonly IAttendanceRepository _iAttendanceRepository;
        private readonly IMapper _mapper;
        public AttendanceManager(IAttendanceRepository iAttendanceRepository,IMapper iMapper)
        {
            _iAttendanceRepository = iAttendanceRepository;
            _mapper = iMapper;
        }

        public AttendanceSession TakeAttendance(AttendanceSessionAddDTO session)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));

            // ensure lists and timestamps are initialized
            session.CreatedAtUtc = DateTime.UtcNow;
            session.Records ??= new List<AttendanceRecord>();
            foreach (var r in session.Records)
            {
                r.UpdatedAtUtc = DateTime.UtcNow;
            }

            // repository methods are async; call synchronously to match interface
            var mappedSession = _mapper.Map<AttendanceSession>(session);
            var result = _iAttendanceRepository.TakeAttendance(mappedSession).GetAwaiter().GetResult();
            return result;
        }

        public AttendanceSession EditAttendance(AttendanceSessionUpdateDTO session)
        {
            if (session == null) throw new ArgumentNullException(nameof(session));
            if (session.Id <= 0) throw new ArgumentException("Session must have a valid Id to edit.", nameof(session));

            // ensure the session exists before attempting an update
            var existing = _iAttendanceRepository.GetAttendance(session.Id).GetAwaiter().GetResult();
            if (existing == null)
                throw new InvalidOperationException($"Attendance session with Id {session.Id} not found.");

            // update records timestamps
            session.Records ??= new List<AttendanceRecord>();
            foreach (var r in session.Records)
            {
                r.UpdatedAtUtc = DateTime.UtcNow;
            }
            var mappedSession = _mapper.Map<AttendanceSession>(session);
            var result = _iAttendanceRepository.EditAttendance(mappedSession).GetAwaiter().GetResult();
            return result;
        }

        public AttendanceSession GetAttendance(int sessionId)
        {
            // Call the repository to get the attendance session synchronously
            var result = _iAttendanceRepository.GetAttendance(sessionId).GetAwaiter().GetResult();
            return result;
        }
    }
}