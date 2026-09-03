using Church.API.Services.Interfaces;
using Church.BLL.Services;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Church.API.Services.Implementations
{
    public class LocalFileStorage : IFileStorage
    {
        private readonly IWebHostEnvironment _env;
        private readonly IHttpContextAccessor _http;

        public LocalFileStorage(IWebHostEnvironment env, IHttpContextAccessor http)
        {
            _env = env;
            _http = http;
        }

        public async Task<string> SaveImageAsync(IFormFile file, CancellationToken ct = default,string foldername=default)
        {
            var ext = await ImageUploadValidator.ValidateAndGetExtensionAsync(file);

            var webRoot = _env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot");
            var uploads = Path.Combine(webRoot, "uploads", foldername);
            Directory.CreateDirectory(uploads);

            var fileName = $"{Guid.NewGuid()}{ext}";
            var fullPath = Path.Combine(uploads, fileName);

            await using var stream = File.Create(fullPath);
            await file.CopyToAsync(stream, ct);

            // key saved in DB
            return $"{foldername}/{fileName}";
        }

        public string GetPublicUrl(string key)
        {
            var req = _http.HttpContext!.Request;
            return $"{req.Scheme}://{req.Host}/uploads/{key}";
        }

        public Task DeleteAsync(string key, CancellationToken ct = default)
        {
            var webRoot = _env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot");
            var uploadsRoot = Path.GetFullPath(Path.Combine(webRoot, "uploads"));
            var fullPath = Path.GetFullPath(
                Path.Combine(uploadsRoot, key.Replace("/", Path.DirectorySeparatorChar.ToString())));

            // Containment check: a key holding "../" segments would otherwise delete arbitrary
            // files outside the uploads directory.
            if (!fullPath.StartsWith(uploadsRoot + Path.DirectorySeparatorChar, StringComparison.Ordinal))
                return Task.CompletedTask;

            if (File.Exists(fullPath)) File.Delete(fullPath);
            return Task.CompletedTask;
        }
    }
}
