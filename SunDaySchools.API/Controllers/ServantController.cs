using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.API.Mapping;
using SunDaySchools.API.Requests;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Implementations;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchoolsDAL.DBcontext;
using SunDaySchoolsDAL.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ServantController : ControllerBase
    {
        private readonly IServantManager _servantManager;
        private readonly IFileStorage _fileStorage;
        private readonly IWebHostEnvironment _env;
        private readonly ProgramContext _db;
        private readonly UserManager<ApplicationUser> _userManager;


        public ServantController(
            IServantManager servantManager,
            IFileStorage fileStorage,
            IWebHostEnvironment env,
            ProgramContext db,
            UserManager<ApplicationUser> userManager)
        {
            _servantManager = servantManager;
            _fileStorage = fileStorage;
            _env = env;
            _db = db;
            _userManager = userManager;
        }

        // Add servant
        [HttpPost]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Create([FromForm(Name = "")] AdminAddServantDTO servant)
        {
            if (servant == null)
            {
                var errors = new Dictionary<string, string[]>
                {
                    ["servant"] = new[] { "The request body cannot be empty." }
                };
                throw new ValidationException(errors);
            }

            await _servantManager.AddAsync(servant, _env.WebRootPath);

            return StatusCode(201, new { message = "Created Successfully" });
        }

        [HttpGet]
        public async Task<ActionResult> GetAll()
        {
            var servants = await _servantManager.GetAllAsync();
            return Ok(servants);
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult> GetById(int id)
        {
            if (id <= 0)
                return BadRequest("Servant id must be a positive integer.");

            var servant = await _servantManager.GetByIdAsync(id);

            if (servant == null)
                throw new NotFoundException($"Servant with id {id} not found.");

            return Ok(servant);
        }

        [HttpGet("select")]
        //[Authorize(Roles = "Admin,SuperAdmin")]
        public async Task<IActionResult> GetServantsForSelection()
        {
            var result = await _servantManager.GetServantsForSelection();
            return Ok(result);
        }

        [HttpPut("{id:int}")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> Update(int id, [FromForm] ServantFormRequest form, CancellationToken ct)
        {
            if (id <= 0)
                return BadRequest("Servant id must be a positive integer.");

            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);

            var updateDto = form.ToUpdateDto();
            updateDto.Id = id;

            if (form.Image is not null && form.Image.Length > 0)
            {
                var key = await _fileStorage.SaveImageAsync(form.Image, ct, "servants");
                updateDto.ImageFileName = key;
                updateDto.ImageUrl = _fileStorage.GetPublicUrl(key);
            }

            await _servantManager.UpdateAsync(updateDto);

            return NoContent();
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteById(int id)
        {
            if (id <= 0)
                return BadRequest("Servant id must be a positive integer.");

            var deleted = await _servantManager.DeleteAsync(id);
            if (!deleted)
                return NotFound();

            return NoContent();
        }

        [Authorize(Roles = "Servant")]
        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile(CancellationToken ct)
        {
            var userId =
                User.FindFirstValue(JwtRegisteredClaimNames.Sub) ??
                User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (string.IsNullOrWhiteSpace(userId))
                return Unauthorized("Missing user id claim.");

            var servant = await _db.Servants
                .AsNoTracking()
                .Include(s => s.ApplicationUser)
                .Include(s => s.Church)
                .Include(s => s.Meeting)
                .Include(s => s.ClassroomServants)
                    .ThenInclude(cs => cs.Classroom)
                .FirstOrDefaultAsync(s => s.ApplicationUserId == userId, ct);

            if (servant == null)
                return NotFound("Servant profile not found for current user.");

            return Ok(new
            {
                servant.Id,
                servant.Name,
                servant.PhoneNumber,
                servant.ImageUrl,
                servant.BirthDate,
                servant.JoiningDate,
                SpiritualBirthDate = (DateOnly?)null,
                Church = servant.Church == null ? null : new { servant.Church.Id, servant.Church.Name },
                Meeting = servant.Meeting == null ? null : new { servant.Meeting.Id, servant.Meeting.Name },
                Classrooms = servant.ClassroomServants
                    .Select(cs => cs.Classroom)
                    .Where(c => c != null)
                    .Select(c => new { c!.Id, c.Name, c.AgeOfMembers })
                    .ToList()
            });
        }

        [Authorize(Roles = "Servant")]
        [HttpPut("profile")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UpdateProfile([FromForm] ServantProfileFormRequest form, CancellationToken ct)
        {
            if (!ModelState.IsValid)
                return ValidationProblem(ModelState);

            var userId =
                User.FindFirstValue(JwtRegisteredClaimNames.Sub) ??
                User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (string.IsNullOrWhiteSpace(userId))
                return Unauthorized("Missing user id claim.");

            var servant = await _db.Servants
                .Include(s => s.ApplicationUser)
                .Include(s => s.ClassroomServants)
                .FirstOrDefaultAsync(s => s.ApplicationUserId == userId, ct);

            if (servant == null)
                return NotFound("Servant profile not found for current user.");

            // Basic fields
            if (form.Name != null) servant.Name = form.Name.Trim();
            if (form.PhoneNumber != null) servant.PhoneNumber = form.PhoneNumber.Trim();
            if (form.BirthDate.HasValue) servant.BirthDate = form.BirthDate;
            if (form.JoiningDate.HasValue) servant.JoiningDate = form.JoiningDate;

            // Tenant fields (optional)
            if (form.ChurchId.HasValue) servant.ChurchId = form.ChurchId;
            if (form.MeetingId.HasValue) servant.MeetingId = form.MeetingId;

            // Keep Identity user in sync where applicable
            if (servant.ApplicationUser != null)
            {
                if (form.PhoneNumber != null)
                    servant.ApplicationUser.PhoneNumber = form.PhoneNumber.Trim();
                if (form.ChurchId.HasValue)
                    servant.ApplicationUser.ChurchId = form.ChurchId;
                if (form.MeetingId.HasValue)
                    servant.ApplicationUser.MeetingId = form.MeetingId;
            }

            // Image
            if (form.Image is not null && form.Image.Length > 0)
            {
                var key = await _fileStorage.SaveImageAsync(form.Image, ct, "servants");
                servant.ImageFileName = key;
                servant.ImageUrl = _fileStorage.GetPublicUrl(key);
            }

            // Classrooms (optional replace)
            if (form.ClassroomIds is not null)
            {
                var desired = form.ClassroomIds
                    .Where(id => id > 0)
                    .Distinct()
                    .ToHashSet();

                servant.ClassroomServants ??= new List<ClassroomServant>();

                var toRemove = servant.ClassroomServants
                    .Where(cs => !desired.Contains(cs.ClassroomId))
                    .ToList();

                foreach (var cs in toRemove)
                    servant.ClassroomServants.Remove(cs);

                var existing = servant.ClassroomServants.Select(cs => cs.ClassroomId).ToHashSet();
                foreach (var id in desired)
                {
                    if (existing.Contains(id)) continue;
                    servant.ClassroomServants.Add(new ClassroomServant
                    {
                        ServantId = servant.Id,
                        ClassroomId = id
                    });
                }
            }

            await _db.SaveChangesAsync(ct);
            return NoContent();
        }
    }
}