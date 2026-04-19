using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;

namespace SunDaySchools.DAL.Repository.Implementations
{
    public class MeetingRepository : IMeetingRepository
    {
        private readonly ProgramContext _context;

        public MeetingRepository(ProgramContext context)
        {
            _context = context;
        }

        public async Task<List<SelectOptionDTO>> GetMeetingsForSelection()
        {
            var meetings = await _meetingRepository.GetMeetingsForSelection();

            return meetings.Select(m => new SelectOptionDTO
            {
                Id = m.Id,
                Name = m.Item2
            }).ToList();
        }

        public async Task<Meeting?> GetByIdAsync(int id)
        {
            return await _context.Meetings
                .Include(m => m.Servants)
                .Include(m => m.Members)
                .FirstOrDefaultAsync(m => m.Id == id);
        }

        public async Task<Meeting?> GetByNameAsync(string name)
        {
            return await _context.Meetings
                .Include(m => m.Servants)
                .Include(m => m.Members)
                .FirstOrDefaultAsync(m => m.Name == name);
        }

        public async Task AddAsync(Meeting meeting)
        {
            await _context.Meetings.AddAsync(meeting);
            await _context.SaveChangesAsync();
        }

        public async Task<List<Meeting>> GetByChurchIdAsync(int churchid)
        {
            return await _context.Meetings
                .Where(c => c.ChurchId == churchid)
                .ToListAsync();
        }

        public async Task UpdateAsync(Meeting meeting)
        {
            _context.Meetings.Update(meeting);
            await _context.SaveChangesAsync();
        }

        public async Task DeleteAsync(int id)
        {
            var meeting = await _context.Meetings.FindAsync(id);
            if (meeting != null)
            {
                _context.Meetings.Remove(meeting);
                await _context.SaveChangesAsync();
            }
        }
    }
}