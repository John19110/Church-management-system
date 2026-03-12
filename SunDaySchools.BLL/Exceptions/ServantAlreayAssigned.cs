using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Exceptions
{
    public class ServantAlreayAssigned :Exception
    {
        public ServantAlreayAssigned(string message = "Servant already assigned to this Class.") : base(message) { }

    }
}
