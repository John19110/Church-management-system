using AutoMapper;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.DAL.Models;
using SunDaySchools.Models;
using System;

namespace SunDaySchools.BLL.AutoMapper
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            // =========================
            // Member
            // =========================
            CreateMap<Member, MemberAddDTO>().ReverseMap();
            CreateMap<Member, MemberReadDTO>()
                .ForMember(dest => dest.FullName,
                           opt => opt.MapFrom(src => src.FullName));
            CreateMap<Member, MemberUpdateDTO>().ReverseMap();
            CreateMap<MemberContact, MemberContactDTO>().ReverseMap();

            // =========================
            // Servant
            // =========================
            CreateMap<ServantAddDTO, Servant>()
                .ForMember(dest => dest.ImageFileName, opt => opt.Ignore())
                .ForMember(dest => dest.ImageUrl, opt => opt.Ignore());

            CreateMap<Servant, ServantReadDTO>().ReverseMap();
            CreateMap<Servant, ServantUpdateDTO>().ReverseMap();

            CreateMap<RegisterServamtinAddAdmin, RegisterServantDTO>();

            // =========================
            // Attendance Record
            // =========================
            CreateMap<AttendanceRecord, AttendanceRecordReadDTO>();
            CreateMap<AttendanceRecordAddDTO, AttendanceRecord>()
                .ForMember(d => d.Id, o => o.Ignore())
                .ForMember(d => d.AttendanceSessionId, o => o.Ignore())
                .ForMember(d => d.AttendanceSession, o => o.Ignore())
                .ForMember(d => d.Member, o => o.Ignore())
                .ForMember(d => d.UpdatedAt,
                           o => o.MapFrom(_ => DateTime.Now));


            CreateMap<AttendanceRecordUpdateDTO, AttendanceRecord>()
                .ForMember(d => d.Id, o => o.Ignore())
                .ForMember(d => d.AttendanceSessionId, o => o.Ignore())
                .ForMember(d => d.AttendanceSession, o => o.Ignore())
                .ForMember(d => d.Member, o => o.Ignore())
                .ForMember(d => d.UpdatedAt,
                           o => o.MapFrom(_ => DateTime.Now));

            // =========================
            // Attendance Session
            // =========================
            CreateMap<AttendanceSession, AttendanceSessionReadDTO>()
                .ForMember(d => d.Records, o => o.MapFrom(s => s.Records));

            CreateMap<AttendanceSessionAddDTO, AttendanceSession>()
                .ForMember(d => d.Id, o => o.Ignore())
                .ForMember(d => d.Classroom, o => o.Ignore())
                .ForMember(d => d.TakenByServant, o => o.Ignore())
                .ForMember(d => d.CreatedAt, o => o.MapFrom(_ => DateTime.UtcNow))
                .ForMember(d => d.Records, o => o.MapFrom(s => s.Records));

            CreateMap<AttendanceSessionUpdateDTO, AttendanceSession>()
                .ForMember(d => d.Classroom, o => o.Ignore())
                .ForMember(d => d.TakenByServant, o => o.Ignore())
                .ForMember(d => d.CreatedAt, o => o.Ignore())
                .ForMember(d => d.Records, o => o.MapFrom(s => s.Records));
        }
    }
}