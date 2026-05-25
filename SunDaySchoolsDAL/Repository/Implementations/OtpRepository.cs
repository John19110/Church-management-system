using Microsoft.EntityFrameworkCore;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchoolsDAL.DBcontext;
using SunDaySchoolsDAL.Models;

namespace SunDaySchools.DAL.Repository.Implementations
{
    public class OtpRepository : IOtpRepository
    {
        private readonly ProgramContext _context;

        public OtpRepository(ProgramContext context)
        {
            _context = context;
        }

        public async Task<OtpVerification> AddAsync(OtpVerification otp)
        {
            await _context.OtpVerifications.AddAsync(otp);
            await _context.SaveChangesAsync();
            return otp;
        }

        public async Task<OtpVerification?> GetLatestActiveAsync(string phoneNumber, OtpPurpose purpose)
        {
            var now = DateTime.UtcNow;
            return await _context.OtpVerifications
                .Where(o =>
                    o.PhoneNumber == phoneNumber &&
                    o.Purpose == purpose &&
                    !o.IsUsed &&
                    o.ExpirationTime > now)
                .OrderByDescending(o => o.CreatedAt)
                .FirstOrDefaultAsync();
        }

        public async Task MarkUsedAsync(int id)
        {
            var otp = await _context.OtpVerifications.FindAsync(id);
            if (otp == null) return;
            otp.IsUsed = true;
            await _context.SaveChangesAsync();
        }

        public async Task IncrementFailedAttemptsAsync(int id)
        {
            var otp = await _context.OtpVerifications.FindAsync(id);
            if (otp == null) return;
            otp.FailedAttempts++;
            await _context.SaveChangesAsync();
        }

        public Task<int> CountSendsSinceAsync(string phoneNumber, DateTime sinceUtc) =>
            _context.OtpVerifications.CountAsync(o =>
                o.PhoneNumber == phoneNumber && o.CreatedAt >= sinceUtc);

        public async Task<DateTime?> GetLatestCreatedAtAsync(string phoneNumber, OtpPurpose purpose)
        {
            return await _context.OtpVerifications
                .Where(o => o.PhoneNumber == phoneNumber && o.Purpose == purpose)
                .OrderByDescending(o => o.CreatedAt)
                .Select(o => (DateTime?)o.CreatedAt)
                .FirstOrDefaultAsync();
        }

        public async Task InvalidateActiveOtpsAsync(string phoneNumber, OtpPurpose purpose)
        {
            var now = DateTime.UtcNow;
            var active = await _context.OtpVerifications
                .Where(o =>
                    o.PhoneNumber == phoneNumber &&
                    o.Purpose == purpose &&
                    !o.IsUsed &&
                    o.ExpirationTime > now)
                .ToListAsync();

            foreach (var otp in active)
                otp.IsUsed = true;

            if (active.Count > 0)
                await _context.SaveChangesAsync();
        }
    }
}
