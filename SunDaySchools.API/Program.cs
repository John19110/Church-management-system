using Microsoft.AspNetCore.Hosting.Server;
using Microsoft.AspNetCore.Hosting.Server.Features;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SunDaySchools.API.Services.Implementations;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.BLL.AutoMapper;
using SunDaySchools.BLL.Manager;
using SunDaySchools.DAL.Repository;
using SunDaySchoolsDAL.DBcontext;
using SunDaySchoolsDAL.Models;
using SunDaySchoolsDAL.Repository;
using System.Diagnostics;
using System.Text;


var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IFileStorage, LocalFileStorage>();


// Add services to the container.
builder.Services.AddControllers();

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
builder.Services.AddScoped<IChildRepository, ChildRepository>();
builder.Services.AddScoped<IChildManager, ChildManager>();
builder.Services.AddScoped<IServantRepository, ServantRepository>();
builder.Services.AddScoped<IServantManager, ServantManager>();
builder.Services.AddScoped<IAccountManager, AccountManager>();



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

// Identity
//this old implementation caused error in authentication

//builder.Services.AddIdentity<ApplicationUser, IdentityRole>()
//    .AddEntityFrameworkStores<ProgramContext>();


builder.Services
    .AddIdentityCore<ApplicationUser>(options => { })
    .AddRoles<IdentityRole>()
    .AddEntityFrameworkStores<ProgramContext>()
    .AddDefaultTokenProviders();

// AutoMapper
builder.Services.AddAutoMapper(m => m.AddProfile(new MappingProfile()));



var app = builder.Build();

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

app.MapControllers();

app.Run();
