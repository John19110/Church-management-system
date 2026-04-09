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

       

        public async Task SaveAsync()
        {
            await _context.SaveChangesAsync();
        }
        public async Task AssignClassToServant(int servantId, int classroomId)
        {
            var exists = await _context.Set<ClassroomServant>()
                .AnyAsync(cs => cs.ServantId == servantId && cs.ClassroomId == classroomId);

            if (exists)
                throw new Exception("Already assigned");

            var relation = new ClassroomServant
            {
                ServantId = servantId,
                ClassroomId = classroomId
            };

            await _context.Set<ClassroomServant>().AddAsync(relation);
            await _context.SaveChangesAsync();
        }

        public async Task<(Servant servant, Classroom classroom)> GetServantAndClassroomAsync(int servantId, int classroomId)
        {
            var servant = await _context.Servants
                .FirstOrDefaultAsync(s => s.Id == servantId);

            var classroom = await _context.Classrooms
                .FirstOrDefaultAsync(c => c.Id == classroomId);

            return (servant, classroom);
        }

        public async Task<bool> ClassroomServantExistsAsync(int servantId, int classroomId)
        {
            return await _context.Set<ClassroomServant>()
                .AnyAsync(cs => cs.ServantId == servantId && cs.ClassroomId == classroomId);
        }


        public async Task AddClassroomServantAsync(ClassroomServant entity)
        {
            await _context.Set<ClassroomServant>().AddAsync(entity);
        }
        //public async Task AddServantAsync(Servant servant)
        //{
        //    await _context.Servants.AddAsync(servant);
        //    await _context.SaveChangesAsync();
        //}
    }
}