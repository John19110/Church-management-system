using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Church.BLL.DTOS.AccountDtos;
using Church.BLL.Manager.Interfaces;
using Church.BLL.Services.AccountDeletion;

namespace Church.API.Controllers
{
    [ApiController]
    [Route("api/account")]
    // Anonymous credential and account-creation endpoints are the cheapest targets for
    // password guessing and mass account creation, so they get a tighter per-IP budget.
    [EnableRateLimiting("auth")]
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
        [AllowAnonymous]
        public async Task<ActionResult> Login([FromBody] LoginDTO loginDto)
        {
            var result = await _accountManager.Login(loginDto);
            return result.ToActionResult();
        }

        [HttpPost("register-church-superadmin")]
        [AllowAnonymous]
        public async Task<ActionResult> RegisterChurchSuperAdmin([FromForm] RegisterChurchAdminDTO dto)
        {
            //_env.WebRootPath is the physical path to your application's web root
            var result = await _accountManager.RegisterChurchSuperAdmin(dto, _env.WebRootPath);
            return result.ToActionResult();
        }

        [HttpPost("register-meeting-admin-new-church")]
        [AllowAnonymous]
        public async Task<ActionResult> RegisterMeetingAdminNewChurch([FromForm] RegisterMeetingAdminNewChurchDTO dto)
        {
            var result = await _accountManager.RegisterMeetingAdminNewChurch(dto, _env.WebRootPath);
            return result.ToActionResult();
        }

        [HttpPost("register-servant")]
        [AllowAnonymous]
        public async Task<ActionResult> RegisterServant([FromForm] RegisterServantDTO dto)
        {
            var result = await _accountManager.RegisterServant(dto, _env.WebRootPath);
            return result.ToActionResult();
        }

        [HttpGet("organization-languages")]
        [AllowAnonymous]
        public async Task<ActionResult> GetOrganizationLanguages([FromQuery] string publicId)
        {
            var dto = await _accountManager.GetOrganizationLanguagesAsync(publicId);
            return Ok(dto);
        }

        [HttpGet("language-profile")]
        [Authorize]
        public async Task<ActionResult> GetLanguageProfile()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var dto = await _accountManager.GetLanguageProfileAsync(userId ?? string.Empty);
            return Ok(dto);
        }

        [HttpPut("preferred-language")]
        [Authorize]
        public async Task<IActionResult> UpdatePreferredLanguage(
            [FromBody] UpdatePreferredLanguageDto dto)
        {
            if (dto == null)
                return BadRequest("Request body is required.");
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            await _accountManager.UpdatePreferredLanguageAsync(
                userId ?? string.Empty,
                dto.PreferredLanguage);
            return NoContent();
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