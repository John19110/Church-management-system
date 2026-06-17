using AutoMapper;
using SunDaySchools.BLL.DTOS;
using SunDaySchools.BLL.DTOS.AccountDtos;
using SunDaySchools.BLL.DTOS.ClsssroomDtos;
using SunDaySchools.BLL.DTOS.Meeting;
using SunDaySchools.BLL.DTOS.CustomFields;
using SunDaySchools.BLL.DTOS.MeetingDtos;
using SunDaySchools.DAL.Models;
using SunDaySchools.DAL.Models.CustomFields;
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
                .ForMember(dest => dest.Name1, opt => opt.MapFrom(src => src.Name1))
                .ForMember(dest => dest.Name2, opt => opt.MapFrom(src => src.Name2))
                .ForMember(dest => dest.Name3, opt => opt.MapFrom(src => src.Name3))
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
            CreateMap<AttendanceRecord, AttendanceRecordReadDTO>()
                .ForMember(d => d.ChildId, o => o.MapFrom(s => s.MemberId))
                .ForMember(d => d.MemberName, o => o.MapFrom(s => s.Member != null ? s.Member.FullName : null));

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

            CreateMap<AttendanceSession, AttendanceSessionSummaryDTO>()
                .ForMember(d => d.RecordsCount, o => o.MapFrom(s => s.Records != null ? s.Records.Count : 0));

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

            // =========================
            // Custom fields
            // =========================
            CreateMap<CustomFieldOption, CustomFieldOptionDto>();
            CreateMap<CustomFieldOptionDto, CustomFieldOption>()
                .ForMember(d => d.Id, o => o.Ignore())
                .ForMember(d => d.Definition, o => o.Ignore());

            CreateMap<CustomFieldDefinition, CustomFieldDefinitionReadDto>();
            CreateMap<CustomFieldDefinitionCreateDto, CustomFieldDefinition>()
                .ForMember(d => d.Id, o => o.Ignore())
                .ForMember(d => d.Options, o => o.Ignore())
                .ForMember(d => d.Values, o => o.Ignore())
                .ForMember(d => d.CreatedAt, o => o.Ignore())
                .ForMember(d => d.UpdatedAt, o => o.Ignore())
                .ForMember(d => d.CreatedBy, o => o.Ignore())
                .ForMember(d => d.IsActive, o => o.Ignore())
                .ForMember(d => d.ChurchId, o => o.Ignore())
                .ForMember(d => d.MeetingId, o => o.Ignore());
        }
    }
}