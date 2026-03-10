using Microsoft.AspNetCore.Identity;

namespace SunDaySchoolsDAL.DBcontext
{
    public static class IdentitySeeder
    {
        public static async Task SeedRolesAsync(RoleManager<IdentityRole> roleManager)
        {
            string[] roles = { "Admin", "Servant" };

            foreach (var role in roles)
            {
                if (!await roleManager.RoleExistsAsync(role))
                {
                    var result=  await roleManager.CreateAsync(new IdentityRole(role));
                    if (!result.Succeeded)
                    {
                        throw new Exception($"Failed to create role {role}");
                    }
                }
                
            }
        }
    }
}