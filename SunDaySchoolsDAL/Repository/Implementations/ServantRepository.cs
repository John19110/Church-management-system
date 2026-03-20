using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;



namespace SunDaySchools.DAL.Repository.Implementations
{
    public class ServantRepository: IServantRepository
    {

        private readonly ProgramContext _context;
        public ServantRepository(ProgramContext context)
        {
            _context = context;
        }
        public IQueryable<Servant> GetAll()
        {
            return _context.Servants
                .Include(s => s.Classrooms)
                .Include(s => s.ApplicationUser);
        }

        public async Task<Servant?> GetById(int id)
        {
            return _context.Servants
                .Include(s => s.Classrooms)
                .Include(s => s.ApplicationUser)
                .FirstOrDefault(s => s.Id == id);
        }


        public async Task<IEnumerable<Classroom>> GetByServantIdAsync(int servantId)
        {
            return await _context.Classrooms
                .Where(c => c.Servants.Any(s => s.Id == servantId))
                .ToListAsync();
        }

        public async Task<Servant?> GetByApplicationUserIdAsync(string applicationUserId)
        {
            return _context.Servants
                .Include(s => s.Classrooms)
                .Include(s => s.ApplicationUser)
                .FirstOrDefault(s => s.ApplicationUserId == applicationUserId);
        }


        //public void Add(Servant servant)
        //{
        //    _context.Servants.Add(servant);
        //    _context.SaveChanges();
        //}

        public  async Task Update(Servant servant)
        {
            _context.SaveChanges();
        }
        public void Delete(int id)
        {
            var servant = _context.Servants.Find(id);
            if (servant != null)
            {
                _context.Servants.Remove(servant);
                _context.SaveChanges();
            }

        }


    }
}
