using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;

namespace SunDaySchools.DAL.Repository.Implementations
{
    public class MemberRepository : IMemberRepository
    {

        private readonly ProgramContext _context;
        public MemberRepository(ProgramContext context)
        {
        _context=context;
        }
        public IQueryable<Member> GetAll()
        {
            return _context.Members
                .Include(c => c.PhoneNumbers);
        }

        public Member? GetById(int id)
        {
            return _context.Members
                .Include(c => c.PhoneNumbers)
                .FirstOrDefault(c => c.Id == id);
        }

        public void Add(Member child)
        {
            _context.Members.Add(child);
            _context.SaveChanges();
        }
       public  void Update(Member child)
        {

            _context.SaveChanges();
           
        }
       public void Delete(int id)
        {
            _context.Members.Remove(_context.Members.Find(id));
            _context.SaveChanges();
        }

        public IQueryable<Member> GetSpecificClassroom(int classroomId)
        {

            return _context.Members.Where(ch => ch.ClassroomId == classroomId);
        }

        public IQueryable<Member> GetSpecificClassroomMembers(int classroomId)
        {

            return _context.Members.Where(ch => ch.ClassroomId == classroomId);
        }
    }
}
