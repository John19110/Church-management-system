using AutoMapper;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.DTOS.ClsssroomDtos;
using SunDaySchools.BLL.DTOS.Meeting;
using SunDaySchools.BLL.DTOS.MeetingDtos;
using SunDaySchools.DAL.Models;
using SunDaySchools.Models;
using System;
using System.Linq;

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

            
            CreateMap< ClassroomAddDTO, Classroom>();
            CreateMap<Classroom, ClassroomReadDTO>()
                .ForMember(d => d.Servants,
                    o => o.MapFrom(s => s.ClassroomServants.Select(cs => cs.Servant)))
                .ForMember(d => d.PastAttendanceSessionsCount,
                    o => o.MapFrom(s => s.AttendanceHistory != null ? s.AttendanceHistory.Count : 0));

           // CreateMap<RegisterServamtinAddAdmin, PendingServantDTO>();





            // =========================
            // Attendance Record
            // =========================
            CreateMap<AttendanceRecord, AttendanceRecordReadDTO>();

            CreateMap<MeetingAddDTO, Meeting>()
                .ForMember(d => d.Weekly_appointment, o => o.MapFrom(s => s.WeeklyAppointment));
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
                .ForMember(d => d.CreatedAt, o => o.MapFrom(_ => DateOnly.FromDateTime(DateTime.UtcNow)))
                .ForMember(d => d.Records, o => o.MapFrom(s => s.Records));

            CreateMap<AttendanceSessionUpdateDTO, AttendanceSession>()
                .ForMember(d => d.Classroom, o => o.Ignore())
                .ForMember(d => d.TakenByServant, o => o.Ignore())
                .ForMember(d => d.CreatedAt, o => o.Ignore())
                .ForMember(d => d.Records, o => o.MapFrom(s => s.Records));


            CreateMap<Meeting, MeetingReadDTO>()
                .ForMember(d => d.WeeklyAppointment, o => o.MapFrom(s => s.Weekly_appointment));
        }
    }
}