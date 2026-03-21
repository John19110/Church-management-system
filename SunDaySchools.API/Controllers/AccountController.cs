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

        public AccountController(IAccountManager accountManager)
        {
            _accountManager = accountManager;
        }

        [HttpPost("login")]
        public async Task<ActionResult> Login([FromBody] LoginDTO loginDto)
        {
            var token = await _accountManager.Login(loginDto);
            return Ok(new { token });
        }

        [HttpPost("register-church-superadmin")]
        public async Task<ActionResult> RegisterChurchSuperAdmin([FromBody] RegisterChurchAdminDTO dto)
        {
            var token = await _accountManager.RegisterChurchSuperAdmin(dto);
            return Ok(new { token });
        }

        [HttpPost("register-meeting-admin-new-church")]
        public async Task<ActionResult> RegisterMeetingAdminNewChurch([FromBody] RegisterMeetingAdminNewChurchDTO dto)
        {
            var token = await _accountManager.RegisterMeetingAdminNewChurch(dto);
            return Ok(new { token });
        }

        [HttpPost("register-meeting-admin-existing-church")]
        public async Task<ActionResult> RegisterMeetingAdminExistingChurch([FromBody] RegisterMeetingAdminExistingChurch dto)
        {
            var token = await _accountManager.RegisterMeetingAdminExistingChurch(dto);
            return Ok(new { token });
        }

        [HttpPost("register-servant")]
        public async Task<ActionResult> RegisterServant([FromForm] RegisterServantDTO dto)
        {
            var token = await _accountManager.RegisterServant(dto);
            return Ok(new { token });
        }
    }
}