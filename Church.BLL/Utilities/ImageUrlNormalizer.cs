namespace Church.BLL.Utilities;

/// Normalizes stored image references to public relative paths for API clients.
public static class ImageUrlNormalizer
{
    public static string? ToPublicRelativePath(string? imageUrl, string? imageFileName)
    {
        var fromUrl = NormalizeStoredValue(imageUrl);
        if (fromUrl != null)
            return fromUrl;

        var fileName = imageFileName?.Trim();
        if (string.IsNullOrEmpty(fileName))
            return null;

        if (fileName.Contains("://", StringComparison.Ordinal))
            return NormalizeStoredValue(fileName);

        if (fileName.StartsWith('/'))
            return fileName;

        if (fileName.StartsWith("members/", StringComparison.OrdinalIgnoreCase) ||
            fileName.StartsWith("servants/", StringComparison.OrdinalIgnoreCase))
            return $"/uploads/{fileName}";

        // Registration photos are stored under wwwroot/images via FileManager.
        return $"/images/{fileName}";
    }

    public static string? NormalizeStoredValue(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return null;

        var trimmed = value.Trim();

        if (Uri.TryCreate(trimmed, UriKind.Absolute, out var absolute))
        {
            var path = absolute.AbsolutePath;
            return string.IsNullOrEmpty(path) ? null : path;
        }

        if (trimmed.StartsWith('/'))
            return trimmed;

        if (trimmed.StartsWith("uploads/", StringComparison.OrdinalIgnoreCase) ||
            trimmed.StartsWith("images/", StringComparison.OrdinalIgnoreCase))
            return $"/{trimmed}";

        return trimmed;
    }
}
