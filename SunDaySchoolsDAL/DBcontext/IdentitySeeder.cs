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
            string[] roles = { "Admin", "Servant" };

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

            var admin = await userManager.FindByNameAsync("john");

            if (admin != null && !await userManager.IsInRoleAsync(admin, "Admin"))
            {
                var result = await userManager.AddToRoleAsync(admin, "Admin");

                if (!result.Succeeded)
                {
                    throw new Exception("Failed to assign Admin role");
                }
            }
        }
    }
}