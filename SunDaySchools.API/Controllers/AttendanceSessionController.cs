using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.BLL.Manager.Interfaces;

namespace SunDaySchools.API.Controllers
{
        [Route("Api/[controller]")]
        [ApiController]
    public class AttendanceSessionController:ControllerBase
    {
        private readonly IAttendanceManager _attendanceManager;
        public AttendanceSessionController(IAttendanceManager attendanceManager)

        {
            _attendanceManager = attendanceManager;


        }





    }
}
