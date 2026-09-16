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
    // This class contains extension methods used to register
    // application-level services into ASP.NET Core's Dependency Injection container.
    //
    // Instead of putting all registrations inside Program.cs,
    // we group related registrations here to keep Program.cs clean.
    public static class ApplicationServiceCollectionExtensions
    {
        // ============================================================
        // APPLICATION SERVICES
        // ============================================================
        //
        // Called from Program.cs like this:
        //
        // builder.Services.AddApplicationServices(builder.Configuration);
        //
        // This method registers services from different layers:
        //
        // API-specific services
        // Business Logic services
        // Repository/Data Access services
        // Tenant-related services
        // Application helpers
        // Mapping
        //
        public static IServiceCollection AddApplicationServices(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            // --------------------------------------------------------
            // 1. Configuration
            // --------------------------------------------------------
            //
            // Binds the "Servants" configuration section to ServantProfileOptions.
            //
            // ServantProfileOptions.SectionName = "Servants"
            //
            // This allows the application to inject ServantProfileOptions
            // through IOptions<ServantProfileOptions>.
            //
            // Example configuration:
            //
            // "Servants": {
            //     "AutoCreateMissingProfile": false
            // }
            services.Configure<ServantProfileOptions>(
                configuration.GetSection(ServantProfileOptions.SectionName));


            // --------------------------------------------------------
            // 2. Tenant Context
            // --------------------------------------------------------
            //
            // TenantContextState contains information about the
            // currently selected church/tenant during the HTTP request.
            //
            // "Scoped" means:
            //
            //     One instance per HTTP request.
            //
            // Example:
            //
            // Request A → TenantContextState instance A
            // Request B → TenantContextState instance B
            //
            // This is important because different requests may belong
            // to different churches/tenants.
            //
            services.AddScoped<TenantContextState>();


            // Register the interface ITenantContext.
            //
            // When another service asks for:
            //
            //     ITenantContext
            //
            // ASP.NET Core will provide the SAME TenantContextState
            // instance that belongs to the current request.
            //
            services.AddScoped<ITenantContext>(
                sp => sp.GetRequiredService<TenantContextState>());


            // --------------------------------------------------------
            // 3. Current User Context
            // --------------------------------------------------------
            //
            // Provides information about the currently authenticated
            // user, usually extracted from HttpContext/JWT claims.
            //
            // Other services can depend on ICurrentUserContext instead
            // of directly depending on HttpContext.
            //
            // Example:
            //
            //     ICurrentUserContext.CurrentUserId
            //     ICurrentUserContext.Roles
            //
            services.AddScoped<ICurrentUserContext, HttpCurrentUserContext>();


            // --------------------------------------------------------
            // 4. JWT Token Service
            // --------------------------------------------------------
            //
            // ITokenService is the abstraction.
            //
            // JwtTokenService is the actual implementation.
            //
            // Therefore, when a class asks for:
            //
            //     ITokenService
            //
            // Dependency Injection creates/provides:
            //
            //     JwtTokenService
            //
            services.AddScoped<ITokenService, JwtTokenService>();


            // --------------------------------------------------------
            // 5. Servant Profile Service
            // --------------------------------------------------------
            //
            // Handles business/application operations related
            // to servant profiles.
            //
            services.AddScoped<IServantProfileService, ServantProfileService>();


            // --------------------------------------------------------
            // 6. File Storage
            // --------------------------------------------------------
            //
            // IFileStorage represents file storage functionality.
            //
            // The current implementation is LocalFileStorage.
            //
            // The advantage of using the interface is that the rest
            // of the application does not need to know HOW files
            // are physically stored.
            //
            // For example, you could later replace:
            //
            //     LocalFileStorage
            //
            // with:
            //
            //     AzureBlobFileStorage
            //
            // without changing the business logic that depends
            // on IFileStorage.
            //
            services.AddScoped<IFileStorage, LocalFileStorage>();


            // --------------------------------------------------------
            // 7. Tenant-Aware Caching
            // --------------------------------------------------------
            //
            // Registers caching services that understand the
            // current tenant/church.
            //
            // This is particularly important in a multi-tenant
            // application because cached data belonging to Church A
            // must not accidentally be returned to Church B.
            //
            services.AddTenantAwareCaching();


            // --------------------------------------------------------
            // 8. Repository Layer
            // --------------------------------------------------------
            //
            // Registers all repositories used by the application.
            //
            // Repository classes are responsible for communicating
            // with the database.
            //
            // Example:
            //
            //     IChurchRepository
            //              ↓
            //        ChurchRepository
            //
            services.AddRepositoryServices();


            // --------------------------------------------------------
            // 9. Manager / Business Logic Layer
            // --------------------------------------------------------
            //
            // Registers the Manager classes.
            //
            // Managers contain application/business operations and
            // coordinate repositories and other services.
            //
            // Example:
            //
            //     IChurchManager
            //              ↓
            //        ChurchManager
            //
            services.AddManagerServices();


            // --------------------------------------------------------
            // 10. Account Deletion
            // --------------------------------------------------------
            //
            // Handles the application logic required to delete
            // an account and its related data.
            //
            services.AddScoped<
                IAccountDeletionService,
                AccountDeletionService
            >();


            // --------------------------------------------------------
            // 11. Public ID Resolution
            // --------------------------------------------------------
            //
            // Resolves public IDs used by the API.
            //
            // Your application uses public IDs/short codes instead
            // of exposing internal database IDs directly in URLs
            // or API responses.
            //
            services.AddScoped<IPublicIdResolver, PublicIdResolver>();


            // --------------------------------------------------------
            // 12. Church Public ID Service
            // --------------------------------------------------------
            //
            // Handles generation/resolution/business logic related
            // to Church public IDs.
            //
            services.AddScoped<
                IChurchPublicIdService,
                ChurchPublicIdService
            >();


            // --------------------------------------------------------
            // 13. Meeting Public ID Service
            // --------------------------------------------------------
            //
            // Handles generation/resolution/business logic related
            // to Meeting public IDs.
            //
            services.AddScoped<
                IMeetingPublicIdService,
                MeetingPublicIdService
            >();


            // --------------------------------------------------------
            // 14. User Registration Approval
            // --------------------------------------------------------
            //
            // Handles registration approval logic.
            //
            // This one is registered using its concrete type directly.
            //
            // Therefore another service can request:
            //
            //     UserRegistrationApprovalService
            //
            // directly from DI.
            //
            services.AddScoped<UserRegistrationApprovalService>();


            // --------------------------------------------------------
            // 15. File Manager
            // --------------------------------------------------------
            //
            // Higher-level file management logic.
            //
            // Notice the difference:
            //
            // IFileStorage → how/where files are physically stored
            //
            // IFileManager → application-level file operations
            //
            services.AddScoped<IFileManager, FileManager>();


            // --------------------------------------------------------
            // 16. Custom Field Validation
            // --------------------------------------------------------
            //
            // Responsible for validating custom fields defined
            // by the application.
            //
            services.AddScoped<
                ICustomFieldValidator,
                CustomFieldValidator
            >();


            // --------------------------------------------------------
            // 17. Custom Field Helper
            // --------------------------------------------------------
            //
            // Helper functionality for working with custom fields.
            //
            // Registered directly because the application requests
            // CustomFieldHelper itself rather than an interface.
            //
            services.AddScoped<CustomFieldHelper>();


            // --------------------------------------------------------
            // 18. Unit of Work
            // --------------------------------------------------------
            //
            // IUnitOfWork represents a unit of database work.
            //
            // It is commonly used to coordinate multiple repository
            // operations and commit them as one logical operation.
            //
            // Example:
            //
            //     Repository A → change
            //     Repository B → change
            //             ↓
            //       UnitOfWork.SaveChanges()
            //
            services.AddScoped<IUnitOfWork, UnitOfWork>();


            // --------------------------------------------------------
            // 19. AutoMapper
            // --------------------------------------------------------
            //
            // Registers AutoMapper and your application's
            // MappingProfile.
            //
            // MappingProfile defines how objects are converted,
            // for example:
            //
            //     Entity → DTO
            //     DTO → Entity
            //
            services.AddAutoMapper(
                m => m.AddProfile(new MappingProfile())
            );


            // Return the same IServiceCollection so that
            // AddApplicationServices() can participate in
            // method chaining in Program.cs.
            //
            // Example:
            //
            // builder.Services
            //     .AddApiServices()
            //     .AddApplicationServices(...)
            //     .AddDatabaseServices(...);
            //
            return services;
        }


        // ============================================================
        // REPOSITORY SERVICES
        // ============================================================
        //
        // This method registers the Data Access / Repository layer.
        //
        // Called internally by:
        //
        //     AddApplicationServices()
        //
        // Each interface is mapped to its concrete repository.
        //
        public static IServiceCollection AddRepositoryServices(
            this IServiceCollection services)
        {
            // Admin database operations
            services.AddScoped<IAdminRepository, AdminRepository>();

            // Attendance database operations
            services.AddScoped<
                IAttendanceRepository,
                AttendanceRepository
            >();

            // Attendance criteria database operations
            services.AddScoped<
                IAttendanceCriterionRepository,
                AttendanceCriterionRepository
            >();

            // Church database operations
            services.AddScoped<IChurchRepository, ChurchRepository>();

            // Classroom database operations
            services.AddScoped<
                IClassroomRepository,
                ClassroomRepository
            >();

            // Member database operations
            services.AddScoped<
                IMemberRepository,
                MemberRepository
            >();

            // Meeting database operations
            services.AddScoped<
                IMeetingRepository,
                MeetingRepository
            >();

            // Servant database operations
            services.AddScoped<
                IServantRepository,
                ServantRepository
            >();

            // Super Admin database operations
            services.AddScoped<
                ISuperAdminRepository,
                SuperAdminRepository
            >();

            // Custom field database operations
            services.AddScoped<
                ICustomFieldRepository,
                CustomFieldRepository
            >();


            // Return IServiceCollection to allow method chaining.
            return services;
        }


        // ============================================================
        // MANAGER SERVICES
        // ============================================================
        //
        // This method registers the Business/Application Logic layer.
        //
        // Managers generally coordinate:
        //
        //     Controller
        //          ↓
        //     Manager
        //          ↓
        //     Repository
        //          ↓
        //     Database
        //
        public static IServiceCollection AddManagerServices(
            this IServiceCollection services)
        {
            // Admin business logic
            services.AddScoped<IAdminManager, AdminManager>();

            // Attendance business logic
            services.AddScoped<
                IAttendanceManager,
                AttendanceManager
            >();

            // Attendance criteria business logic
            services.AddScoped<
                IAttendanceCriterionManager,
                AttendanceCriterionManager
            >();

            // Account business logic
            services.AddScoped<IAccountManager, AccountManager>();

            // Church business logic
            services.AddScoped<IChurchManager, ChurchManager>();

            // Classroom business logic
            services.AddScoped<
                IClassroomManager,
                ClassroomManager
            >();

            // Member business logic
            services.AddScoped<
                IMemberManager,
                MemberManager
            >();

            // Meeting business logic
            services.AddScoped<
                IMeetingManager,
                MeetingManager
            >();

            // Servant business logic
            services.AddScoped<
                IServantManager,
                ServantManager
            >();

            // Super Admin business logic
            services.AddScoped<
                ISuperAdminManager,
                SuperAdminManager
            >();

            // Custom field business logic
            services.AddScoped<
                ICustomFieldManager,
                CustomFieldManager
            >();

            // Handles forms that can work with multiple/unified
            // entity types.
            services.AddScoped<
                IUnifiedEntityFormManager,
                UnifiedEntityFormManager
            >();


            // Return IServiceCollection for method chaining.
            return services;
        }
    }
}