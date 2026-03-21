using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SunDaySchoolsDAL.Models;
using SunDaySchools.DAL.Models;
using Microsoft.EntityFrameworkCore;

namespace SunDaySchools.DAL.Repository.Implementations
{
    public class MeetingRepository
    {

       
            private readonly ProgramContext _context;
            public MeetingRepository(ProgramContext context)
            {
                _context = context;
            }
            public IQueryable<Meeting> GetAll()
            {
                return _context.Meetings
                    .Include(c => c.Servants)
                    .Include(c=>c.Members);
            }

            public Meeting? GetById(int id)
            {
            return _context.Meetings
                .Include(c => c.Servants)
                .Include(c => c.Members)
                .FirstOrDefault(s => s.Id == id);
            ;
        }

            public void Add(Meeting meeting)
            {
                _context.Meetings.Add(meeting);
                _context.SaveChanges();
            }
            public void Update(Meeting meeting)
            {

                _context.SaveChanges();

            }
            public void Delete(int id)
            {
                _context.Meetings.Remove(_context.Meetings.Find(id));
                _context.SaveChanges();
            }

         
        
    

}
}
