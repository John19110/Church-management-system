using AutoMapper;
using AutoMapper;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Repository.Implementations;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.Models;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class AdminManager : IAdminManager
    {

        
    private readonly IAdminRepository _adminRepository;
    private readonly IMapper _mapper;


        public AdminManager(IAdminRepository adminRepository,IMapper mapper)
        {
            _adminRepository = adminRepository;
            _mapper = mapper;
        }



        public void AssignClassToServant(int ServantId, int ClassroomId)
        {
            var (servant, classroom) = _adminRepository.AssignClassToServant(ServantId, ClassroomId);

            if (servant is null)
                throw new NotFoundException($"Servant with id : {ServantId} not found");

            if (classroom is null)
                throw new NotFoundException($"Classroom with id : {ClassroomId} not found");


            if (servant.Classrooms.Contains(classroom))
            {
                throw new Exception("Servant is already assigned to this class");
            }


            servant.Classrooms.Add( classroom);

            if (!classroom.Servants.Any(s => s.Id == servant.Id))
            {
                classroom.Servants.Add(servant);
            }

            _adminRepository.Save();

        }


        public void AddServant(ServantAddDTO servant)
        {

            var model=_mapper.Map<Servant>(servant);
            _adminRepository.AddServant(model);

        }

        

    }

       }
