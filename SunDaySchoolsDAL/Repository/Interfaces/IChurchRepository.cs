using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Repository.Interfaces
{
    public  interface IChurchRepository
    {
         Task AddChurch(Church church);

    }
}
