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
            CreateMap<Child, ChildReadDTO>()
                .ForMember(dest => dest.FullName, opt => opt.MapFrom(src => src.FullName));
            CreateMap<Child, ChildUpdateDTO>().ReverseMap();
            CreateMap<ChildContact, ChildContactDTO>().ReverseMap();

            CreateMap<Servant,ServantAddDTO>().ReverseMap();
            CreateMap<Servant, ServantReadDTO>().ReverseMap();
            CreateMap<Servant, ServantUpdateDTO>().ReverseMap();




        }
}
}
