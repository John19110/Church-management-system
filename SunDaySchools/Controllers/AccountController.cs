using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.Manager;
using SunDaySchools.BLL.DTOS.AccountDtos;


namespace SunDaySchools.API.Controllers
{
    [ApiController]
    [Route("Api/[controller]")]
    public class AccountController:ControllerBase

    {
        private readonly IAccountManager _accountmanager;
        public AccountController(IAccountManager accountmanager)
        {
            _accountmanager = accountmanager;

        }
        [HttpPost]
        [Route("Login")]
        public async Task<ActionResult>Login (LoginDTO logindto)
        {

            var result = await _accountmanager.Login(logindto);
            if (result == null)
            {
                return Unauthorized();
            }
            else return Ok(result); 
        }


        [HttpPost]
        [Route("Register")]
        [Consumes("multipart/form-data")]
        public async Task<ActionResult> Register([FromForm]RegisterDTO registerdto)
        {

            var result = await _accountmanager.Register(registerdto);
            if (result == null)
            {
                return Unauthorized();
            }
            else return Ok(result);
        }


    }
}
