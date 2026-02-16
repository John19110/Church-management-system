using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;

namespace SunDaySchools.DAL.Repository.Implementations
{
    public class ChildRepository : IChildRepository
    {

        private readonly ProgramContext _context;
        public ChildRepository(ProgramContext context)
        {
        _context=context;
        }
        public IQueryable<Child> GetAll()
        {
            return _context.Children
                .Include(c => c.PhoneNumbers);
        }

        public Child? GetById(int id)
        {
            return _context.Children
                .Include(c => c.PhoneNumbers)
                .FirstOrDefault(c => c.Id == id);
        }

        public void Add(Child child)
        {
            _context.Children.Add(child);
            _context.SaveChanges();
        }
       public  void Update(Child child)
        {

            _context.SaveChanges();
           
        }
       public void Delete(int id)
        {
            _context.Children.Remove(_context.Children.Find(id));
            _context.SaveChanges();
        }
    }
}
