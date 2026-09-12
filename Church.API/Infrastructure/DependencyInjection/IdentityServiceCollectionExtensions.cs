using Church.DAL.DBcontext;
using Church.DAL.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace Church.API.Infrastructure.DependencyInjection
{
    public static class IdentityServiceCollectionExtensions
    {
        public static IServiceCollection AddIdentityServices(this IServiceCollection services)
        {
            services.Configure<IdentityOptions>(options =>
            {
                options.User.AllowedUserNameCharacters =
                    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._@+ " +
                    "ءآأؤإئابةتثجحخدذرزسشصضطظعغفقكلمنهوىي";

                // Phone-number accounts are easy to target; require more than Identity's default 6.
                options.Password.RequiredLength = 8;
                options.Password.RequireDigit = true;
                options.Password.RequireLowercase = true;
                options.Password.RequireUppercase = false;
                options.Password.RequireNonAlphanumeric = false;

                // Effective only because login records failures via UserManager.AccessFailedAsync.
                options.Lockout.AllowedForNewUsers = true;
                options.Lockout.MaxFailedAccessAttempts = 8;
                options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
            });

            services
                .AddIdentityCore<ApplicationUser>(options => { })
                .AddRoles<IdentityRole>()
                .AddEntityFrameworkStores<ProgramContext>()
                .AddDefaultTokenProviders();

            services.RemoveAll<IUserValidator<ApplicationUser>>();
            services.AddScoped<IUserValidator<ApplicationUser>, Church.BLL.Identity.ApplicationUserValidator>();

            return services;
        }
    }
}
