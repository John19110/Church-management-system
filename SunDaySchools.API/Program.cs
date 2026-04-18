using Microsoft.AspNetCore.Hosting.Server;
using Microsoft.AspNetCore.Hosting.Server.Features;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Microsoft.AspNetCore.Identity;
using SunDaySchoolsDAL.DBcontext;
using SunDaySchools.API.Services.Implementations;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.BLL.AutoMapper;
using SunDaySchools.BLL.Manager.Implementations;
using SunDaySchools.BLL.Manager.Interfaces;
using SunDaySchools.DAL.Repository.Implementations;
using SunDaySchools.DAL.Repository.Interfaces;
using SunDaySchoolsDAL.DBcontext;
using SunDaySchoolsDAL.Models;
using System.Diagnostics;
using System.Text;
using SunDaySchools.API.Json;


var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IFileStorage, LocalFileStorage>();
builder.Services.AddProblemDetails();

// Add services to the container.
builder.Services.AddControllers()
    .AddJsonOptions(o =>
    {
        o.JsonSerializerOptions.Converters.Add(new TimeOnlyJsonConverter());
    });

builder.Services.AddHttpContextAccessor();

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

builder.Services.AddScoped<IChurchRepository, ChurchRepository>();

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


builder.Services.AddScoped<IUnitOfWork,UnitOfWork>();






//Authuntication
builder.Services.AddAuthentication(option =>
{

    option.DefaultAuthenticateScheme = "jwt";
    option.DefaultChallengeScheme = "jwt";

}).AddJwtBearer(
    "jwt", options =>
    {
        var SecretKey = builder.Configuration.GetSection("SecretKey").Value;
        var SecretKeybyte = Encoding.UTF8.GetBytes(SecretKey);
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
    options.UseSqlServer(builder.Configuration.GetConnectionString("cs"));
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

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
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

            if (!string.IsNullOrWhiteSpace(baseUrl))
            {
                var swaggerUrl = baseUrl.TrimEnd('/') + "/swagger";
                Process.Start(new ProcessStartInfo
                {
                    FileName = swaggerUrl,
                    UseShellExecute = true
                });
            }
        }
        catch
        {
            // If something blocks browser launching, ignore to avoid crashing the app.
        }
    });
}

// If you are NOT running HTTPS (and you see it only listens on http),
// this redirection can prevent reaching Swagger unless HTTPS is configured.
// You can comment it out if needed.
//app.UseHttpsRedirection();

app.UseStaticFiles();


//// If you use [Authorize] anywhere, you should enable authentication:
app.UseAuthentication();
app.UseAuthorization();

app.UseMiddleware<MeetingMiddleware>();
app.UseMiddleware<ChurchMiddleware>();
app.UseMiddleware<GlobalExceptionMiddleware>();

app.MapControllers();
app.MapGet("/", () => Results.Redirect("/swagger"));
app.Run();
