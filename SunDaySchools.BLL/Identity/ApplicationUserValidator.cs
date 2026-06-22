using System.Linq;
using Microsoft.AspNetCore.Identity;
using SunDaySchoolsDAL.Models;

namespace SunDaySchools.BLL.Identity
{
    /// <summary>
    /// Validates user name format only. Usernames are not required to be unique;
    /// phone numbers are the unique login identifier.
    /// </summary>
    public sealed class ApplicationUserValidator : IUserValidator<ApplicationUser>
    {
        public Task<IdentityResult> ValidateAsync(
            UserManager<ApplicationUser> manager,
            ApplicationUser user)
        {
            var errors = new List<IdentityError>();
            var userName = manager.NormalizeName(user.UserName ?? string.Empty);

            if (string.IsNullOrWhiteSpace(userName))
            {
                errors.Add(new IdentityError
                {
                    Code = "InvalidUserName",
                    Description = "Username is required."
                });
            }
            else
            {
                var allowed = manager.Options.User.AllowedUserNameCharacters;
                if (userName.Any(c => !allowed.Contains(c)))
                {
                    errors.Add(new IdentityError
                    {
                        Code = "InvalidUserName",
                        Description = "Username contains invalid characters."
                    });
                }
            }

            return Task.FromResult(
                errors.Count == 0
                    ? IdentityResult.Success
                    : IdentityResult.Failed(errors.ToArray()));
        }
    }
}
