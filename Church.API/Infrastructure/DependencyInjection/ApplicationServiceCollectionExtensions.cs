using Church.API.Infrastructure.Auth;
using Church.API.Infrastructure.Caching;
using Church.API.Infrastructure.Tenant;
using Church.API.Services.Implementations;
using Church.API.Services.Interfaces;
using Church.BLL.Abstractions;
using Church.BLL.Application.Servants;
using Church.BLL.AutoMapper;
using Church.BLL.Configuration;
using Church.BLL.Manager.Implementations;
using Church.BLL.Manager.Interfaces;
using Church.BLL.Services;
using Church.BLL.Services.AccountDeletion;
using Church.BLL.Services.CustomFields;
using Church.DAL.Abstractions;
using Church.DAL.Repository.Implementations;
using Church.DAL.Repository.Interfaces;

namespace Church.API.Infrastructure.DependencyInjection
{
    public static class ApplicationServiceCollectionExtensions
    {
        public static IServiceCollection AddApplicationServices(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            services.Configure<ServantProfileOptions>(
                configuration.GetSection(ServantProfileOptions.SectionName));

            services.AddScoped<TenantContextState>();
            services.AddScoped<ITenantContext>(sp => sp.GetRequiredService<TenantContextState>());
            services.AddScoped<ICurrentUserContext, HttpCurrentUserContext>();
            services.AddScoped<ITokenService, JwtTokenService>();
            services.AddScoped<IServantProfileService, ServantProfileService>();
            services.AddScoped<IFileStorage, LocalFileStorage>();
            services.AddTenantAwareCaching();

            services.AddRepositoryServices();
            services.AddManagerServices();

            services.AddScoped<IAccountDeletionService, AccountDeletionService>();
            services.AddScoped<IPublicIdResolver, PublicIdResolver>();
            services.AddScoped<IChurchPublicIdService, ChurchPublicIdService>();
            services.AddScoped<IMeetingPublicIdService, MeetingPublicIdService>();
            services.AddScoped<UserRegistrationApprovalService>();
            services.AddScoped<IFileManager, FileManager>();
            services.AddScoped<ICustomFieldValidator, CustomFieldValidator>();
            services.AddScoped<CustomFieldHelper>();
            services.AddScoped<IUnitOfWork, UnitOfWork>();

            services.AddAutoMapper(m => m.AddProfile(new MappingProfile()));

            return services;
        }

        public static IServiceCollection AddRepositoryServices(this IServiceCollection services)
        {
            services.AddScoped<IAdminRepository, AdminRepository>();
            services.AddScoped<IAttendanceRepository, AttendanceRepository>();
            services.AddScoped<IAttendanceCriterionRepository, AttendanceCriterionRepository>();
            services.AddScoped<IChurchRepository, ChurchRepository>();
            services.AddScoped<IClassroomRepository, ClassroomRepository>();
            services.AddScoped<IMemberRepository, MemberRepository>();
            services.AddScoped<IMeetingRepository, MeetingRepository>();
            services.AddScoped<IServantRepository, ServantRepository>();
            services.AddScoped<ISuperAdminRepository, SuperAdminRepository>();
            services.AddScoped<ICustomFieldRepository, CustomFieldRepository>();
            return services;
        }

        public static IServiceCollection AddManagerServices(this IServiceCollection services)
        {
            services.AddScoped<IAdminManager, AdminManager>();
            services.AddScoped<IAttendanceManager, AttendanceManager>();
            services.AddScoped<IAttendanceCriterionManager, AttendanceCriterionManager>();
            services.AddScoped<IAccountManager, AccountManager>();
            services.AddScoped<IChurchManager, ChurchManager>();
            services.AddScoped<IClassroomManager, ClassroomManager>();
            services.AddScoped<IMemberManager, MemberManager>();
            services.AddScoped<IMeetingManager, MeetingManager>();
            services.AddScoped<IServantManager, ServantManager>();
            services.AddScoped<ISuperAdminManager, SuperAdminManager>();
            services.AddScoped<ICustomFieldManager, CustomFieldManager>();
            services.AddScoped<IUnifiedEntityFormManager, UnifiedEntityFormManager>();
            return services;
        }
    }
}
