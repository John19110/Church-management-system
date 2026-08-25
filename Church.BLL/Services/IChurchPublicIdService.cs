namespace Church.BLL.Services
{
    public interface IChurchPublicIdService
    {
        Task<string> GenerateUniqueAsync(CancellationToken cancellationToken = default);

        bool IsShortFormat(string? publicId);

        string Normalize(string publicId);
    }
}
