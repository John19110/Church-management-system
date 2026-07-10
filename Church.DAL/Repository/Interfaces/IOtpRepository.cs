using Church.DAL.Models;

namespace Church.DAL.Repository.Interfaces
{
    public interface IOtpRepository
    {
        Task<OtpVerification> AddAsync(OtpVerification otp);
        Task<OtpVerification?> GetLatestActiveAsync(string phoneNumber, OtpPurpose purpose);
        Task MarkUsedAsync(int id);
        Task IncrementFailedAttemptsAsync(int id);
        Task<int> CountSendsSinceAsync(string phoneNumber, DateTime sinceUtc);
        Task<DateTime?> GetLatestCreatedAtAsync(string phoneNumber, OtpPurpose purpose);
        Task InvalidateActiveOtpsAsync(string phoneNumber, OtpPurpose purpose);
    }
}
