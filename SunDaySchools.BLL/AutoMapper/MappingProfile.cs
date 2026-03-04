using AutoMapper;
using SunDaySchools.BLL.DTOS;
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
            // Child
            // =========================
            CreateMap<Child, ChildAddDTO>().ReverseMap();

            CreateMap<Child, ChildReadDTO>()
                .ForMember(dest => dest.FullName,
                           opt => opt.MapFrom(src => src.FullName));

            CreateMap<Child, ChildUpdateDTO>().ReverseMap();

            CreateMap<ChildContact, ChildContactDTO>().ReverseMap();


            // =========================
            // Servant
            // =========================
            CreateMap<Servant, ServantAddDTO>().ReverseMap();
            CreateMap<Servant, ServantReadDTO>().ReverseMap();
            CreateMap<Servant, ServantUpdateDTO>().ReverseMap();


            // =========================
            // Attendance Record
            // =========================

            // Entity -> ReadDTO
            CreateMap<AttendanceRecord, AttendanceRecordReadDTO>();

            // AddDTO -> Entity
            CreateMap<AttendanceRecordAddDTO, AttendanceRecord>()
                .ForMember(d => d.Id, o => o.Ignore())
                .ForMember(d => d.AttendanceSessionId, o => o.Ignore())
                .ForMember(d => d.AttendanceSession, o => o.Ignore())
                .ForMember(d => d.Child, o => o.Ignore())
                .ForMember(d => d.UpdatedAtUtc,
                           o => o.MapFrom(_ => DateTime.UtcNow));


            // =========================
            // Attendance Session
            // =========================

            // Entity -> ReadDTO ✅ (Correct direction)
            CreateMap<AttendanceSession, AttendanceSessionReadDTO>()
                .ForMember(d => d.Records,
                           o => o.MapFrom(s => s.Records));

            // AddDTO -> Entity
            CreateMap<AttendanceSessionAddDTO, AttendanceSession>()
                .ForMember(d => d.Id, o => o.Ignore())
                .ForMember(d => d.Classroom, o => o.Ignore())
                .ForMember(d => d.TakenByServant, o => o.Ignore())
                .ForMember(d => d.CreatedAt,
                           o => o.MapFrom(_ => DateTime.Now))
                .ForMember(d => d.Records,
                           o => o.MapFrom(s => s.Records));

            // UpdateDTO -> Entity
            CreateMap<AttendanceSessionUpdateDTO, AttendanceSession>()
                .ForMember(d => d.Classroom, o => o.Ignore())
                .ForMember(d => d.TakenByServant, o => o.Ignore())
                .ForMember(d => d.CreatedAt, o => o.Ignore()) // don't overwrite
                .ForMember(d => d.Records,
                           o => o.MapFrom(s => s.Records));
        }
    }
}