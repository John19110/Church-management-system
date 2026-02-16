using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.API.Controllers
{

    [ApiController]
    [Route("Api/[controller]")]

    public class RoleController : ControllerBase
    {


    private readonly RoleManager<IdentityRole> _roleManager;
    public RoleController(RoleManager<IdentityRole>rolemanager)
    {
        _roleManager = rolemanager;

    }

        [HttpPost("create")]
        public async Task<IActionResult> CreateRole()
        {
            string roleName = "Servant";
            
            if (!await _roleManager.RoleExistsAsync(roleName))
            {
                await _roleManager.CreateAsync(new IdentityRole(roleName));
            }

            return Ok("Role Created");
        }

    }
    }
