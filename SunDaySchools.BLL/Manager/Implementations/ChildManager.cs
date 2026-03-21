using AutoMapper;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.Exceptions;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Repository.Implementations;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager.Implementations
{
    public class MemberManager :IMemberManager
    {

        private readonly IMemberRepository _memberReposatory;
        private readonly IMapper _mapper;   
        public MemberManager(IMemberRepository memberReposatory,IMapper mapper)
        {
            _memberReposatory = memberReposatory;
            _mapper = mapper;
        }
       public  IEnumerable<MemberReadDTO> GetAll()
        {
          return  _mapper.Map<IEnumerable<MemberReadDTO>>(_memberReposatory.GetAll().ToList());
        }
        MemberReadDTO? IMemberManager.GetById(int id)
        {
          return  _mapper.Map<MemberReadDTO>(_memberReposatory.GetById(id));
        }
        public IEnumerable<MemberReadDTO> GetSpecificClassroom(int ClassroomId)
        {
            return _mapper.Map<IEnumerable<MemberReadDTO>>(_memberReposatory.GetSpecificClassroom(ClassroomId).ToList());

        }


         public void Add(MemberAddDTO memberdto)
        {

            {
                string? fileName = null;

                if (memberdto.Image != null)
                {
                    fileName = Guid.NewGuid().ToString() + Path.GetExtension(memberdto.Image.FileName);

                    var filePath = Path.Combine("wwwroot/images", fileName);

                    using (var stream = new FileStream(filePath, FileMode.Create))
                    {
                        memberdto.Image.CopyTo(stream);
                    }
                }



             var  model= _mapper.Map<Member>(memberdto);
                _memberReposatory.Add(model);

                model.ImageFileName = fileName;
                model.ImageUrl = fileName != null ? $"/images/{fileName}" : null;

            }
        }
        void IMemberManager.Update(MemberUpdateDTO MemberUpdateDTO)
        {
            _memberReposatory.Update(_mapper.Map(MemberUpdateDTO, _memberReposatory.GetById(MemberUpdateDTO.Id)));

        }

        public void Delete(int id)
        {
            var member = _memberReposatory.GetById(id);
            if (member == null)
                throw new NotFoundException($"Member with id {id} not found.");

            _memberReposatory.Delete(id);
        }



    }

}
