using Microsoft.AspNetCore.Http;

public interface IFileManager
{
    Task<(string? fileName, string? url)> SaveImageAsync(IFormFile? file, string webRootPath,string folderName);
}