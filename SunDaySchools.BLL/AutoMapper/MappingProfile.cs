using AutoMapper;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.AutoMapper
{
    public class MappingProfile :Profile
    {
        public MappingProfile()
        {

            CreateMap<Child, ChildAddDTO>().ReverseMap();
            CreateMap<Child, ChildReadDTO>().ReverseMap();
            CreateMap<Child, ChildUpdateDTO>().ReverseMap();
            CreateMap<ChildContact, ChildContactDto>().ReverseMap();

            CreateMap<Servant,ServantAddDTO>().ReverseMap();
            CreateMap<Servant, ServantReadDTO>().ReverseMap();
            CreateMap<Servant, ServantUpdateDTO>().ReverseMap();




        }
}
}
