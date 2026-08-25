namespace Church.BLL.Services
{
    public interface IMeetingPublicIdService
    {
        /// <summary>Generates a short code (e.g. M7K2P9) unique within the church and globally.</summary>
        Task<string> GenerateUniqueAsync(int churchId, CancellationToken cancellationToken = default);

        bool IsShortFormat(string? publicId);

        string Normalize(string publicId);
    }

}
