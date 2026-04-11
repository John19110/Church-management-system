using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Manager.Interfaces;

namespace SunDaySchools.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AccountController : ControllerBase
    {
        private readonly IAccountManager _accountManager;
        private readonly IWebHostEnvironment _env;

        // ✅ Inject BOTH dependencies
        public AccountController(IAccountManager accountManager, IWebHostEnvironment env)
        {
            _accountManager = accountManager;
            _env = env;
        }

        [HttpPost("login")]
        public async Task<ActionResult> Login([FromBody] LoginDTO loginDto)
        {
            var token = await _accountManager.Login(loginDto);
            return Ok(new { token });
        }

        [HttpPost("register-church-superadmin")]
        public async Task<ActionResult> RegisterChurchSuperAdmin([FromForm] RegisterChurchAdminDTO dto)
        {
            var token = await _accountManager.RegisterChurchSuperAdmin(dto, _env.WebRootPath);
            return Ok(new { token });
        }

        [HttpPost("register-meeting-admin-new-church")]
        public async Task<ActionResult> RegisterMeetingAdminNewChurch([FromForm] RegisterMeetingAdminNewChurchDTO dto)
        {
            var token = await _accountManager.RegisterMeetingAdminNewChurch(dto, _env.WebRootPath);
            return Ok(new { token });
        }

        [HttpPost("register-servant")]
        public async Task<ActionResult> RegisterServant([FromForm] RegisterServantDTO dto)
        {
            var token = await _accountManager.RegisterServant(dto, _env.WebRootPath);
            return Ok(new { token });
        }

        /// <summary>
        /// Acknowledges logout for the current JWT principal. JWTs are stateless — the client must
        /// discard the token; this endpoint validates the token once (audit / future revocation hooks).
        /// </summary>
        [HttpPost("logout")]
        [Authorize]
        public IActionResult Logout()
        {
            return NoContent();
        }
    }
}