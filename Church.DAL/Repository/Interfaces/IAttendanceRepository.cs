using Church.DAL.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Church.DAL.Repository.Interfaces
{
    public interface IAttendanceRepository
    {
        Task  Take(AttendanceSession session);
        Task  Edit(AttendanceSession session);
        Task<AttendanceSession> Get(int SessionId);
        Task<List<AttendanceSession>> GetByClassroom(int classroomId);

    }
}
