using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Manager.Interfaces;

namespace SunDaySchools.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AccountController : ControllerBase
    {
        private readonly IAccountManager _accountmanager;

        public AccountController(IAccountManager accountmanager)
        {
            _accountmanager = accountmanager;
        }

        // =========================
        // LOGIN
        // =========================
        [HttpPost("login")]
        public async Task<ActionResult> Login(LoginDTO loginDto)
        {
            var result = await _accountmanager.Login(loginDto);

            return Ok(new { token = result });
        }

        // =========================
        // REGISTER CHURCH ADMIN
        // =========================
        [HttpPost("register-admin")]
        public async Task<ActionResult> RegisterChurchAdmin(RegisterChurchAdminDTO dto)
        {
            var result = await _accountmanager.RegisterChurchSuperAdmin(dto);

            return Ok(new { token = result });
        }

        // =========================
        // REGISTER SERVANT
        // =========================
        [HttpPost("register-servant")]
        public async Task<ActionResult> RegisterServant(RegisterServantDTO dto)
        {
            var result = await _accountmanager.RegisterServant(dto);

            return Ok(new { token = result });
        }
    }
}