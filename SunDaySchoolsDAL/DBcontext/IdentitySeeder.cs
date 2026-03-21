using Microsoft.AspNetCore.Identity;
using SunDaySchoolsDAL.Models;

namespace SunDaySchoolsDAL.DBcontext
{
    public static class IdentitySeeder
    {
        public static async Task SeedIdentityAsync(
            RoleManager<IdentityRole> roleManager,
            UserManager<ApplicationUser> userManager)
        {
            string[] roles = { "Admin", "Servant","SuperAdmin" };

            foreach (var role in roles)
            {
                if (!await roleManager.RoleExistsAsync(role))
                {
                    var result = await roleManager.CreateAsync(new IdentityRole(role));

                    if (!result.Succeeded)
                    {
                        throw new Exception($"Failed to create role {role}");
                    }
                }
            }

        
        }
    }
}