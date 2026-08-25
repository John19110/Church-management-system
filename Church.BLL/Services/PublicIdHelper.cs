namespace Church.BLL.Services
{
    public static class PublicIdHelper
    {
        public static bool IsValidChurchPublicId(string? publicId)
        {
            if (string.IsNullOrWhiteSpace(publicId))
                return false;

            var trimmed = publicId.Trim();
            if (ChurchPublicIdPatterns.IsShortFormat(trimmed))
                return true;

            return Guid.TryParse(trimmed, out _);
        }

        public static bool IsValidMeetingPublicId(string? publicId)
        {
            if (string.IsNullOrWhiteSpace(publicId))
                return false;

            var trimmed = publicId.Trim();
            if (MeetingPublicIdPatterns.IsShortFormat(trimmed))
                return true;

            return Guid.TryParse(trimmed, out _);
        }

        public static bool IsValidOrganizationPublicId(string? publicId) =>
            IsValidChurchPublicId(publicId) || IsValidMeetingPublicId(publicId);

        public static bool IsValidFormat(string? publicId) => IsValidChurchPublicId(publicId);

        public static string Normalize(string publicId) => publicId.Trim();
    }
}
