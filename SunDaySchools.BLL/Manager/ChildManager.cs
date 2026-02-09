using AutoMapper;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.Models;
using SunDaySchoolsDAL.DBcontext;
using SunDaySchoolsDAL.Repository;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.Manager
{
    public class ChildManager :IChildManager
    {

        private readonly IChildRepository _childReposatory;
        private readonly IMapper _mapper;   
        public ChildManager(IChildRepository childReposatory,IMapper mapper)
        {
            _childReposatory = childReposatory;
            _mapper = mapper;
        }
       public  IEnumerable<ChildReadDTO> GetAll()
        {
          return  _mapper.Map<IEnumerable<ChildReadDTO>>(_childReposatory.GetAll().ToList());
        }
        ChildReadDTO IChildManager.GetById(int id)
        {
          return  _mapper.Map<ChildReadDTO>(_childReposatory.GetById(id));
        }
        
         public  void Add(ChildAddDTO child)
        {
            _childReposatory.Add(_mapper.Map<Child>(child));
        }
        void IChildManager.Update(ChildUpdateDTO ChildUpdateDTO)
        {
            _childReposatory.Update(_mapper.Map<ChildUpdateDTO, Child>(ChildUpdateDTO, _childReposatory.GetById(ChildUpdateDTO.Id)));

        }

        void IChildManager.Delete(int id)
        {

            _childReposatory.Delete(id);    
        }




    }

}
