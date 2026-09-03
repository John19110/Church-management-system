using Church.BLL.Exceptions;
using Microsoft.AspNetCore.Http;

namespace Church.BLL.Services
{
    /// <summary>
    /// Shared validation for user-supplied images. Uploads are written under wwwroot and served
    /// publicly by the static file middleware, so an unvalidated extension would let a caller
    /// publish .html/.svg/.js on the API's own origin (stored XSS). The client-supplied filename,
    /// extension and Content-Type are all untrusted.
    /// </summary>
    public static class ImageUploadValidator
    {
        public const long MaxBytes = 5 * 1024 * 1024;

        private static readonly HashSet<string> AllowedExtensions =
            new(StringComparer.OrdinalIgnoreCase) { ".jpg", ".jpeg", ".png", ".webp" };

        /// <summary>Leading bytes that must match the claimed image type, so the extension alone is not trusted.</summary>
        private static readonly (byte[] Signature, string[] Extensions)[] Signatures =
        {
            (new byte[] { 0xFF, 0xD8, 0xFF }, new[] { ".jpg", ".jpeg" }),
            (new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }, new[] { ".png" }),
            (new byte[] { 0x52, 0x49, 0x46, 0x46 }, new[] { ".webp" })
        };

        /// <summary>
        /// Validates the upload and returns the safe, lower-cased extension to store it under.
        /// </summary>
        public static async Task<string> ValidateAndGetExtensionAsync(IFormFile file)
        {
            var extension = Path.GetExtension(file.FileName);

            if (!AllowedExtensions.Contains(extension))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Image"] = new[] { "Only .jpg, .jpeg, .png and .webp images are allowed." }
                });
            }

            if (file.Length <= 0 || file.Length > MaxBytes)
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Image"] = new[] { "Image must be between 1 byte and 5 MB." }
                });
            }

            await EnsureContentMatchesExtensionAsync(file, extension);

            return extension.ToLowerInvariant();
        }

        private static async Task EnsureContentMatchesExtensionAsync(IFormFile file, string extension)
        {
            var expected = Signatures.FirstOrDefault(s =>
                s.Extensions.Contains(extension, StringComparer.OrdinalIgnoreCase));

            if (expected.Signature is null)
                return;

            var header = new byte[expected.Signature.Length];

            await using var input = file.OpenReadStream();

            if (await input.ReadAtLeastAsync(header, header.Length, throwOnEndOfStream: false)
                    != header.Length
                || !header.SequenceEqual(expected.Signature))
            {
                throw new ValidationException(new Dictionary<string, string[]>
                {
                    ["Image"] = new[] { "The uploaded file is not a valid image." }
                });
            }
        }
    }
}
