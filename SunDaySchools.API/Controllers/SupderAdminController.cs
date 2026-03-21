using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.API.Mapping;
using SunDaySchools.API.Requests;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using System.Security.Claims;

namespace SunDaySchools.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SupderAdminController : ControllerBase
    {
        private readonly ISuperAdminManager _iSuperAdminManager;
        public SupderAdminController(ISuperAdminManager iSuperAdminManager)
        {
            _iSuperAdminManager = iSuperAdminManager;

        }



        [HttpGet("get-pending-admins")]
        public  async Task<ActionResult<List<PendingServantDTO>>> GetPendinAdmins()
        {
          var PendingAdmins=  await _iSuperAdminManager.GetPendingAdmins();
            return Ok(PendingAdmins);
        }





    }
}
