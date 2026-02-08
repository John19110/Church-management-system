using Microsoft.AspNetCore.Hosting.Server;
using Microsoft.AspNetCore.Hosting.Server.Features;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SunDaySchools.API.Services.Implementations;
using SunDaySchools.API.Services.Interfaces;
using SunDaySchools.BLL.AutoMapper;
using SunDaySchools.BLL.Manager;
using SunDaySchools.DAL.Repository;
using SunDaySchoolsDAL.DBcontext;
using SunDaySchoolsDAL.Models;
using SunDaySchoolsDAL.Repository;
using System.Diagnostics;


var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<IFileStorage, LocalFileStorage>();


// Add services to the container.
builder.Services.AddControllers();

// Swagger / OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// DI
builder.Services.AddScoped<IChildRepository, ChildRepository>();
builder.Services.AddScoped<IChildManager, ChildManager>();
builder.Services.AddScoped<IServantRepository, ServantRepository>();
builder.Services.AddScoped<IServantManager, ServantManager>();

// DbContext
builder.Services.AddDbContext<ProgramContext>(options =>
{
    options.UseSqlServer(builder.Configuration.GetConnectionString("cs"));
});

// Identity
builder.Services.AddIdentity<ApplicationUser, IdentityRole>()
    .AddEntityFrameworkStores<ProgramContext>();

// AutoMapper
builder.Services.AddAutoMapper(m => m.AddProfile(new MappingProfile()));

// OPTIONAL: If you DON'T want to force a fixed port, REMOVE this line.
// builder.WebHost.UseUrls("http://localhost:5029");

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
app.UseHttpsRedirection();
app.UseStaticFiles();


// If you use [Authorize] anywhere, you should enable authentication:
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
