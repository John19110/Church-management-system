using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;

namespace SunDaySchools.DAL.Repository.Implementations
{
    public class AdminRepository : IAdminRepository
    {
        private readonly ProgramContext _context;

        public AdminRepository(ProgramContext context)
        {
            _context = context;
        }

        public async Task<(Servant? servant, Classroom? classroom)> AssignClassToServantAsync(int servantId, int classroomId)
        {
            var servant = await _context.Servants
                .FirstOrDefaultAsync(p => p.Id == servantId);

            var classroom = await _context.Classrooms
                .Include(c => c.Servants)
                .FirstOrDefaultAsync(c => c.Id == classroomId);

            return (servant, classroom);
        }

        public async Task SaveAsync()
        {
            await _context.SaveChangesAsync();
        }

        public async Task AddServantAsync(Servant servant)
        {
            await _context.Servants.AddAsync(servant);
            await _context.SaveChangesAsync();
        }
    }
}