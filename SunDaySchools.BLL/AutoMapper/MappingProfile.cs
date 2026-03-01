using AutoMapper;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.DAL.Models;
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

            CreateMap<AttendanceRecordAddDTO, AttendanceRecord>()
                       .ForMember(d => d.Id, o => o.Ignore())
                       .ForMember(d => d.AttendanceSessionId, o => o.Ignore())
                       .ForMember(d => d.AttendanceSession, o => o.Ignore())
                       .ForMember(d => d.Child, o => o.Ignore())
                       .ForMember(d => d.UpdatedAtUtc, o => o.MapFrom(_ => DateTime.UtcNow));

            // Session Add mapping (DTO -> Entity)
            CreateMap<AttendanceSessionAddDTO, AttendanceSession>()
                .ForMember(d => d.Id, o => o.Ignore())
                .ForMember(d => d.Classroom, o => o.Ignore())
                .ForMember(d => d.TakenByServant, o => o.Ignore())
                .ForMember(d => d.CreatedAtUtc, o => o.MapFrom(_ => DateTime.UtcNow))
                .ForMember(d => d.Records, o => o.MapFrom(s => s.Records));

            // Update mapping (DTO -> Entity) - adjust based on your DTO shape
            CreateMap<AttendanceSessionUpdateDTO, AttendanceSession>()
                .ForMember(d => d.Classroom, o => o.Ignore())
                .ForMember(d => d.TakenByServant, o => o.Ignore())
                .ForMember(d => d.CreatedAtUtc, o => o.Ignore()) // don't overwrite created time
                .ForMember(d => d.Records, o => o.MapFrom(s => s.Records));

        }
}
}
