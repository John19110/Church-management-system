using SunDaySchools.DAL.Repository.Implementations;
using SunDaySchools.DAL.Repository.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class AdminManager
    {
        private readonly IAdminRepository _adminRepository;


        public AdminManager(IAdminRepository adminRepository)
        {
            _adminRepository = adminRepository;
        }

        public void AssignClassToServant(int ClassroomId,int ServantId)

        {
            var ClassAndServant = _adminRepository.AssignClassToServant(ClassroomId, ServantId);


        }





    }
}
