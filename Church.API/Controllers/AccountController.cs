using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Church.BLL.DTOS.AccountDtos;
using Church.BLL.Manager.Interfaces;
using Church.BLL.Services.AccountDeletion;

namespace Church.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AccountController : ControllerBase
    {
        private readonly IAccountManager _accountManager;
        private readonly IAccountDeletionService _accountDeletionService;
        private readonly IWebHostEnvironment _env;

        public AccountController(
            IAccountManager accountManager,
            IAccountDeletionService accountDeletionService,
            IWebHostEnvironment env)
        {
            _accountManager = accountManager;
            _accountDeletionService = accountDeletionService;
            _env = env;
        }

        [HttpPost("login")]
        public async Task<ActionResult> Login([FromBody] LoginDTO loginDto)
        {
            var result = await _accountManager.Login(loginDto);
            return result.ToActionResult();
        }

        [HttpPost("register-church-superadmin")]
        public async Task<ActionResult> RegisterChurchSuperAdmin([FromForm] RegisterChurchAdminDTO dto)
        {
            var result = await _accountManager.RegisterChurchSuperAdmin(dto, _env.WebRootPath);
            return result.ToActionResult();
        }

        [HttpPost("register-meeting-admin-new-church")]
        public async Task<ActionResult> RegisterMeetingAdminNewChurch([FromForm] RegisterMeetingAdminNewChurchDTO dto)
        {
            var result = await _accountManager.RegisterMeetingAdminNewChurch(dto, _env.WebRootPath);
            return result.ToActionResult();
        }

        [HttpPost("register-servant")]
        public async Task<ActionResult> RegisterServant([FromForm] RegisterServantDTO dto)
        {
            var result = await _accountManager.RegisterServant(dto, _env.WebRootPath);
            return result.ToActionResult();
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

        /// <summary>
        /// Permanently deletes the authenticated account and its linked personal data.
        /// </summary>
        /// <response code="204">The account was permanently deleted.</response>
        /// <response code="401">Authentication is missing or invalid.</response>
        /// <response code="404">The authenticated account no longer exists.</response>
        [HttpDelete]
        [Authorize]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> DeleteCurrentAccount(
            CancellationToken cancellationToken)
        {
            await _accountDeletionService.DeleteCurrentAccountAsync(
                _env.WebRootPath,
                cancellationToken);
            return NoContent();
        }
    }
}