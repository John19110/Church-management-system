using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.Manager.Implementations;
using SunDaySchools.BLL.Manager.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
namespace SunDaySchools.API.Controllers
{
    [ApiController]
    [Route("Api/[controller]")]
    public class AdminController : ControllerBase
    {

        private readonly IAdminManager _adminManager;
        public AdminController(IAdminManager adminmanager)
        {
            _adminManager = adminmanager;

        }

        [HttpPut("assign-class/{ServantId}/{ClassroomId}")]

        public ActionResult AssignClassToServant(int ServantId,int ClassroomId)
        {


            _adminManager.AssignClassToServant(ServantId, ClassroomId);
            return Ok();

        }






    }

}