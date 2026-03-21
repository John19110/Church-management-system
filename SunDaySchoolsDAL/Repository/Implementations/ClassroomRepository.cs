




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
    public class ClassroomRepository
    {
          private readonly ProgramContext _context;
            public ClassroomRepository(ProgramContext context)
            {
                _context = context;
            }
            public IQueryable<Classroom> GetAll()
            {
                return _context.Classrooms
                    .Include(c => c.Servants)
                    .Include(c => c.Members)
                    .Include(c => c.AttendanceHistory);
            }

            public Classroom? GetById(int id)
            {
                return _context.Classrooms
                    .Include(c => c.Servants)
                    .Include(c => c.Members)
                    .Include(c => c.AttendanceHistory)
                    .FirstOrDefault(s => s.Id == id);
            ;
        }

            public void Add(Classroom classroom)
            {
                _context.Classrooms.Add(classroom);
                _context.SaveChanges();
            }
            public void Update(Classroom classroom)
            {

                _context.SaveChanges();

            }
            public void Delete(int id)
            {
                _context.Classrooms.Remove(_context.Classrooms.Find(id));
                _context.SaveChanges();
            }





        }
    }


