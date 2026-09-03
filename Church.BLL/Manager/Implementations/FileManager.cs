using Microsoft.AspNetCore.Http;
using Church.BLL.Services;

public class FileManager : IFileManager
{
    public async Task<(string? fileName, string? url)> SaveImageAsync(
        IFormFile? file,
        string webRootPath,
        string folderName)
    {
        if (file == null)
            return (null, null);

        var extension = await ImageUploadValidator.ValidateAndGetExtensionAsync(file);

        // Never reuse the client filename: a generated name removes traversal and overwrite risk.
        var fileName = Guid.NewGuid().ToString() + extension;

        var folderPath = Path.Combine(webRootPath, folderName);

        // Ensure directory exists
        Directory.CreateDirectory(folderPath);

        var filePath = Path.Combine(folderPath, fileName);

        using var stream = new FileStream(filePath, FileMode.Create);
        await file.CopyToAsync(stream);

        var url = $"/{folderName}/{fileName}";

        return (fileName, url);
    }
}
