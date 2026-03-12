using Microsoft.EntityFrameworkCore;
using SunDaySchools.BLL.Exceptions;
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

        public void AssignClassToServant(int ClassroomId, int ServantId)
        {
            var (servant, classroom) = _adminRepository.AssignClassToServant(ServantId, ClassroomId);

            if (servant is null)
                throw new NotFoundException($"Servant with id : {ServantId} not found");

            if (classroom is null)
                throw new NotFoundException($"Classroom with id : {ClassroomId} not found");

            servant.ClassroomId = ClassroomId;
            if (!classroom.Servants.Any(s => s.Id == servant.Id))
            {
                classroom.Servants.Add(servant);
            }
            else
            {
                throw new Exception("Sarvent already assigned to this class");
            }

                _adminRepository.Save();
        }
        }





    }
