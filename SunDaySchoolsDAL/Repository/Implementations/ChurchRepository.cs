using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SunDaySchoolsDAL.DBcontext;

namespace SunDaySchools.DAL.Repository.Implementations
{
    public class ChurchRepository: IChurchRepository
    {
        private readonly ProgramContext _context;
        public ChurchRepository(ProgramContext context)
        {
            _context = context;

        }

        public async Task AddAsync(Church church)
        {
 
            await _context.Churches.AddAsync(church);
            await _context.SaveChangesAsync();
        }

        public async Task<Church?> GetByIdAsync(int id)
        {
            return await _context.Churches
                .Include(c => c.Members)
                .Include(c => c.Servants)
                .Include(c => c.Meetings)
                .FirstOrDefaultAsync(c => c.Id == id);
        }
        public async Task<Church?> GetByNameAsync(string churchName)
        { 

             return await _context.Churches
                .Include(c => c.Members)
                .Include(c => c.Servants)
                .Include(c => c.Meetings)
                .FirstOrDefaultAsync(c => c.Name == churchName);
        }



    }
}
