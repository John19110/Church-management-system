using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.API.Services.Interfaces
{
    public interface IFileStorage
    {
        Task<string> SaveChildImageAsync(IFormFile file, CancellationToken ct = default);

        string GetPublicUrl(string key);

        Task DeleteAsync(string key, CancellationToken ct = default);
    }
}
