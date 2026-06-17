using Microsoft.AspNetCore.Hosting.Server;
using Microsoft.AspNetCore.Hosting.Server.Features;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SunDaySchoolsDAL.DBcontext;
using SunDaySchools.API.Services.Implementations;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.BLL.AutoMapper;
using SunDaySchools.BLL.Configuration;
using SunDaySchools.BLL.Manager.Implementations;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Repository.Implementations;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchoolsDAL.Models;
using System.Diagnostics;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using SunDaySchools.API.Authorization;
using SunDaySchools.API.Json;
using SunDaySchools.API.Filters;
using SunDaySchools.API.Middlewares;
using System.Text.Json.Serialization;
using SunDaySchools.BLL.Services;
using SunDaySchools.BLL.Services.CustomFields;
using SunDaySchools.BLL.Configuration;
using SunDaySchools.BLL.Services.Auth.Interfaces;
using SunDaySchools.BLL.Services.Auth.Implementations;
using SunDaySchools.BLL.Abstractions;
using SunDaySchools.BLL.Application.Servants;
using SunDaySchools.DAL.Abstractions;
using SunDaySchools.API.Infrastructure;
using SunDaySchools.API.Infrastructure.Auth;
using SunDaySchools.API.Infrastructure.Tenant;


var builder = WebApplication.CreateBuilder(args);

builder.Services.Configure<ServantProfileOptions>(
    builder.Configuration.GetSection(ServantProfileOptions.SectionName));
builder.Services.Configure<WhatsAppOptions>(
    builder.Configuration.GetSection(WhatsAppOptions.SectionName));
builder.Services.Configure<OtpOptions>(
    builder.Configuration.GetSection(OtpOptions.SectionName));

builder.Services.AddScoped<IFileStorage, LocalFileStorage>();
builder.Services.AddProblemDetails();

// Add services to the container.
builder.Services.AddControllers(options =>
    {
        options.Filters.Add<FormDataExceptionFilter>();
    })
    .AddJsonOptions(o =>
    {
        ApiJsonSerializerOptions.Configure(o.JsonSerializerOptions);
        o.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
        o.JsonSerializerOptions.Converters.Add(new TimeOnlyJsonConverter());
    });

builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var errors = context.ModelState
            .Where(e => e.Value?.Errors.Count > 0)
            .ToDictionary(
                e => e.Key,
                e => e.Value!.Errors.Select(x => x.ErrorMessage).ToArray());

        return new BadRequestObjectResult(new
        {
            success = false,
            errorCode = "MODEL_BINDING_ERROR",
            message = "One or more fields failed model binding or validation.",
            errors
        });
    };
});

builder.Services.AddHttpContextAccessor();

// Layered architecture: tenant + user context (API adapters → BLL/DAL abstractions)
builder.Services.AddScoped<TenantContextState>();
builder.Services.AddScoped<ITenantContext>(sp => sp.GetRequiredService<TenantContextState>());
builder.Services.AddScoped<ICurrentUserContext, HttpCurrentUserContext>();
builder.Services.AddScoped<ITokenService, JwtTokenService>();
builder.Services.AddScoped<IServantProfileService, ServantProfileService>();

// Swagger / OpenAPI
builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "SunDaySchools API", Version = "v1" });

    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter token like: Bearer {your token}"
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }
    });
});

// DI

builder.Services.AddScoped<IAdminManager,AdminManager >();
builder.Services.AddScoped<IAdminRepository, AdminRepository>();

builder.Services.AddScoped<IAttendanceRepository, AttendanceRepository>();
builder.Services.AddScoped<IAttendanceManager, AttendanceManager>();

builder.Services.AddScoped<IAccountManager, AccountManager>();
builder.Services.AddScoped<IOtpRepository, OtpRepository>();
builder.Services.AddScoped<IAuthOtpManager, AuthOtpManager>();
builder.Services.AddScoped<IWhatsAppMessagingService, WhatsAppCloudMessagingService>();
builder.Services.AddHttpClient("WhatsApp");

builder.Services.AddScoped<IChurchRepository, ChurchRepository>();
builder.Services.AddScoped<IChurchManager, ChurchManager>();
builder.Services.AddScoped<IPublicIdResolver, PublicIdResolver>();

builder.Services.AddScoped<IClassroomManager, ClassroomManager>();
builder.Services.AddScoped<IClassroomRepository, ClassroomRepository>();

builder.Services.AddScoped<IFileManager, FileManager>();

builder.Services.AddScoped<IMemberManager, MemberManager>();
builder.Services.AddScoped<IMemberRepository, MemberRepository>();

builder.Services.AddScoped<IMeetingManager, MeetingManager>();
builder.Services.AddScoped<IMeetingRepository, MeetingRepository>();

builder.Services.AddScoped<IServantManager, ServantManager>();
builder.Services.AddScoped<IServantRepository, ServantRepository>();

builder.Services.AddScoped<ISuperAdminRepository, SuperAdminRepository>();
builder.Services.AddScoped<ISuperAdminManager, SuperAdminManager>();

builder.Services.AddScoped<ICustomFieldRepository, CustomFieldRepository>();
builder.Services.AddScoped<ICustomFieldManager, CustomFieldManager>();
builder.Services.AddScoped<ICustomFieldValidator, CustomFieldValidator>();
builder.Services.AddScoped<CustomFieldHelper>();

builder.Services.AddScoped<IUnifiedEntityFormManager, UnifiedEntityFormManager>();

builder.Services.AddScoped<IUnitOfWork,UnitOfWork>();

builder.Services.AddCustomFieldAuthorization();






//Authuntication
builder.Services.AddAuthentication(option =>
{

    option.DefaultAuthenticateScheme = "jwt";
    option.DefaultChallengeScheme = "jwt";

}).AddJwtBearer(
    "jwt", options =>
    {
        var secretKey = builder.Configuration["SecretKey"];
        if (string.IsNullOrWhiteSpace(secretKey))
        {
            throw new InvalidOperationException(
                "Missing required configuration value 'SecretKey'. " +
                "Set it in appsettings.Production.json or as an environment variable in the hosting environment.");
        }

        var SecretKeybyte = Encoding.UTF8.GetBytes(secretKey);
        SecurityKey securityKey = new SymmetricSecurityKey(SecretKeybyte);
        options.TokenValidationParameters = new TokenValidationParameters()
        {
            IssuerSigningKey = securityKey,
            // we use them if we have another independent server for validation
            ValidateIssuer = false,
            ValidateAudience = false
        };
    }
    );





// DbContext
builder.Services.AddDbContext<ProgramContext>(options =>
{
    var cs = builder.Configuration.GetConnectionString("cs");
    if (string.IsNullOrWhiteSpace(cs))
    {
        throw new InvalidOperationException(
            "Missing required connection string 'ConnectionStrings:cs'. " +
            "Set it in appsettings.Production.json or as an environment variable in the hosting environment.");
    }

    // Migrations live in the DAL project (SunDaySchools.DAL), not in the API host.
    options.UseSqlServer(cs, sql =>
        sql.MigrationsAssembly(typeof(ProgramContext).Assembly.GetName().Name));
});


builder.Services.Configure<IdentityOptions>(options =>
{
    options.User.AllowedUserNameCharacters =
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._@+ " +
        "ءآأؤإئابةتثجحخدذرزسشصضطظعغفقكلمنهوىي";
});



builder.Services
    .AddIdentityCore<ApplicationUser>(options => { })
    .AddRoles<IdentityRole>()
    .AddEntityFrameworkStores<ProgramContext>()
    .AddDefaultTokenProviders();

// AutoMapper
builder.Services.AddAutoMapper(m => m.AddProfile(new MappingProfile()));



var app = builder.Build();

// Apply EF migrations and repair PublicId columns if hosting DB is out of sync.
DatabaseBootstrap.ApplyMigrationsAndRepairSchema(app.Services, app.Logger);

var whatsAppConfig = app.Configuration.GetSection(WhatsAppOptions.SectionName).Get<WhatsAppOptions>();
if (whatsAppConfig == null || !whatsAppConfig.Enabled)
{
    app.Logger.LogWarning("WhatsApp OTP delivery is disabled (WhatsApp:Enabled = false).");
}
else if (string.IsNullOrWhiteSpace(whatsAppConfig.AccessToken)
         || string.IsNullOrWhiteSpace(whatsAppConfig.PhoneNumberId))
{
    app.Logger.LogWarning(
        "WhatsApp is enabled but AccessToken or PhoneNumberId is missing. Set environment variables WhatsApp__AccessToken and WhatsApp__PhoneNumberId on the host.");
}

try
{
    using (var scope = app.Services.CreateScope())
    {
        var services = scope.ServiceProvider;

        var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();

        await IdentitySeeder.SeedIdentityAsync(roleManager, userManager);
    }
}
catch (Exception ex)
{
    Console.WriteLine("Seeder failed: " + ex.Message);
}

// Must be first so it catches exceptions from all middleware/controllers.
app.UseMiddleware<GlobalExceptionMiddleware>();

// Configure the HTTP request pipeline.
//if (app.Environment.IsDevelopment())
//{
    app.UseSwagger();
    app.UseSwaggerUI();

    // Auto-open Swagger in default browser (works with ANY port)
    app.Lifetime.ApplicationStarted.Register(() =>
    {
       try
        {
            var server = app.Services.GetRequiredService<IServer>();
            var addressesFeature = server.Features.Get<IServerAddressesFeature>();

            // Prefer https if available, otherwise http
            var baseUrl = addressesFeature?.Addresses?
                .OrderByDescending(a => a.StartsWith("https", StringComparison.OrdinalIgnoreCase))
                .FirstOrDefault();

            //if (!string.IsNullOrWhiteSpace(baseUrl))
            //{
            //    var swaggerUrl = baseUrl.TrimEnd('/') + "/swagger";
            //    Process.Start(new ProcessStartInfo
            //    {
            //        FileName = swaggerUrl,
            //        UseShellExecute = true
            //    });
            //}
        }
        catch
        {
            // If something blocks browser launching, ignore to avoid crashing the app.
        }
    });
//}

// If you are NOT running HTTPS (and you see it only listens on http),
// this redirection can prevent reaching Swagger unless HTTPS is configured.
// You can comment it out if needed.
app.UseHttpsRedirection();

app.UseStaticFiles();


//// If you use [Authorize] anywhere, you should enable authentication:
app.UseAuthentication();
app.UseAuthorization();

app.UseMiddleware<TenantContextPopulationMiddleware>();

app.MapControllers();
//if (app.Environment.IsDevelopment())
//{
    app.MapGet("/", () => Results.Redirect("/swagger"));
//}
app.Run();
