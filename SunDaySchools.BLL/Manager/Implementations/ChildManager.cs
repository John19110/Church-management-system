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
    public class ChildManager :IMemberManager
    {

        private readonly IMemberRepository _childReposatory;
        private readonly IMapper _mapper;   
        public ChildManager(IMemberRepository childReposatory,IMapper mapper)
        {
            _childReposatory = childReposatory;
            _mapper = mapper;
        }
       public  IEnumerable<MemberReadDTO> GetAll()
        {
          return  _mapper.Map<IEnumerable<MemberReadDTO>>(_childReposatory.GetAll().ToList());
        }
        MemberReadDTO? IMemberManager.GetById(int id)
        {
          return  _mapper.Map<MemberReadDTO>(_childReposatory.GetById(id));
        }
        public IEnumerable<MemberReadDTO> GetSpecificClassroom(int ClassroomId)
        {
            return _mapper.Map<IEnumerable<MemberReadDTO>>(_childReposatory.GetSpecificClassroom(ClassroomId).ToList());

        }


         public void Add(MemberAddDTO childdto)
        {

            {
                string? fileName = null;

                if (childdto.Image != null)
                {
                    fileName = Guid.NewGuid().ToString() + Path.GetExtension(childdto.Image.FileName);

                    var filePath = Path.Combine("wwwroot/images", fileName);

                    using (var stream = new FileStream(filePath, FileMode.Create))
                    {
                        childdto.Image.CopyTo(stream);
                    }
                }



             var  model= _mapper.Map<Member>(childdto);
            _childReposatory.Add(model);

                model.ImageFileName = fileName;
                model.ImageUrl = fileName != null ? $"/images/{fileName}" : null;

            }
        }
        void IMemberManager.Update(MemberUpdateDTO ChildUpdateDTO)
        {
            _childReposatory.Update(_mapper.Map(ChildUpdateDTO, _childReposatory.GetById(ChildUpdateDTO.Id)));

        }

        public void Delete(int id)
        {
            var child = _childReposatory.GetById(id);
            if (child == null)
                throw new NotFoundException($"Child with id {id} not found.");

            _childReposatory.Delete(id);
        }



    }

}
