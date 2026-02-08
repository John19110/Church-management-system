using Microsoft.EntityFrameworkCore;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;
using SunDaySchoolsDAL.Repository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;



namespace SunDaySchools.DAL.Repository
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
            return _context.Servants;
        }

        public Servant? GetById(int id)
        {
            return _context.Servants.FirstOrDefault(c => c.Id == id);
        }

        public void Add(Servant servant)
        {
            _context.Servants.Add(servant);
            _context.SaveChanges();
        }
        public void Update(Servant servant)
        {

            _context.SaveChanges();

        }
        public void Delete(int id)
        {
            _context.Servants.Remove(_context.Servants.Find(id));
            _context.SaveChanges();
        }


    }
}
