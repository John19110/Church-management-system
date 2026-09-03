using Microsoft.AspNetCore.Hosting.Server;
using Microsoft.AspNetCore.Hosting.Server.Features;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Church.DAL.Infrastructure;
using Church.DAL.DBcontext;
using Church.API.Services.Implementations;
using Church.API.Services.Interfaces;
using Church.BLL.AutoMapper;
using Church.BLL.Configuration;
using Church.BLL.Manager.Implementations;
using Church.BLL.Manager.Interfaces;
using Church.DAL.Repository.Implementations;
using Church.DAL.Repository.Interfaces;
using Church.DAL.Models;
using System.Diagnostics;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Church.API.Authorization;
using Microsoft.AspNetCore.Authorization;
using Church.API.Json;
using Church.API.Filters;
using Church.API.Middlewares;
using System.Text.Json.Serialization;
using Church.BLL.Services;
using Church.BLL.Services.CustomFields;
using Church.BLL.Abstractions;
using Church.BLL.Application.Servants;
using Church.DAL.Abstractions;
using Church.API.Infrastructure;
using Church.API.Infrastructure.Auth;
using Church.API.Infrastructure.Tenant;
using Church.API.Infrastructure.Caching;
using Church.BLL.Services.AccountDeletion;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Server.Kestrel.Core;


var builder = WebApplication.CreateBuilder(args);

builder.Services.Configure<ServantProfileOptions>(
    builder.Configuration.GetSection(ServantProfileOptions.SectionName));

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
            message = "Validation failed",
            errors
        });
    };
});

builder.Services.AddHttpContextAccessor();

// The anonymous registration endpoints accept multipart uploads. The framework default allows a
// ~128 MB body, which lets an unauthenticated caller exhaust disk and bandwidth; profile photos
// never need more than a few megabytes.
builder.Services.Configure<FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = 8 * 1024 * 1024;
    options.ValueLengthLimit = 1024 * 1024;
    options.MultipartHeadersLengthLimit = 32 * 1024;
});

builder.Services.Configure<KestrelServerOptions>(options =>
{
    options.Limits.MaxRequestBodySize = 8 * 1024 * 1024;
});

// Layered architecture: tenant + user context (API adapters → BLL/DAL abstractions)
builder.Services.AddScoped<TenantContextState>();
builder.Services.AddScoped<ITenantContext>(sp => sp.GetRequiredService<TenantContextState>());
builder.Services.AddScoped<ICurrentUserContext, HttpCurrentUserContext>();
builder.Services.AddScoped<ITokenService, JwtTokenService>();
builder.Services.AddScoped<IServantProfileService, ServantProfileService>();
builder.Services.AddTenantAwareCaching();

// Swagger / OpenAPI
builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "Church API", Version = "v1" });

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
builder.Services.AddScoped<IAttendanceCriterionRepository, AttendanceCriterionRepository>();
builder.Services.AddScoped<IAttendanceCriterionManager, AttendanceCriterionManager>();

builder.Services.AddScoped<IAccountManager, AccountManager>();
builder.Services.AddScoped<IAccountDeletionService, AccountDeletionService>();

builder.Services.AddScoped<IChurchRepository, ChurchRepository>();
builder.Services.AddScoped<IChurchManager, ChurchManager>();
builder.Services.AddScoped<IPublicIdResolver, PublicIdResolver>();
builder.Services.AddScoped<IChurchPublicIdService, ChurchPublicIdService>();
builder.Services.AddScoped<IMeetingPublicIdService, MeetingPublicIdService>();
builder.Services.AddScoped<UserRegistrationApprovalService>();

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

// Deny by default: any endpoint without an explicit [AllowAnonymous] requires authentication.
// Without this, a controller that simply forgets [Authorize] is silently public.
builder.Services.AddAuthorization(options =>
{
    options.FallbackPolicy = new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build();
});






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

        // A short HMAC key makes offline brute-force of the signing secret feasible, which would
        // let an attacker mint tokens for any user, church and role.
        var secretKeyBytes = Encoding.UTF8.GetBytes(secretKey);
        if (secretKeyBytes.Length < 32)
        {
            throw new InvalidOperationException(
                "Configuration value 'SecretKey' must be at least 32 bytes (256 bits) to safely sign HS256 tokens.");
        }

        SecurityKey securityKey = new SymmetricSecurityKey(secretKeyBytes);
        options.TokenValidationParameters = new TokenValidationParameters()
        {
            IssuerSigningKey = securityKey,
            ValidateIssuerSigningKey = true,
            // Pin the algorithm so a token cannot be presented under a weaker/unexpected alg.
            ValidAlgorithms = new[] { SecurityAlgorithms.HmacSha256 },
            ValidateLifetime = true,
            // Default 5-minute skew keeps revoked/expired tokens usable for too long.
            ClockSkew = TimeSpan.FromSeconds(30),
            // we use them if we have another independent server for validation
            ValidateIssuer = false,
            ValidateAudience = false
        };

        // Stateless JWTs must stop authorizing immediately after account deletion.
        options.Events = new JwtBearerEvents
        {
            OnTokenValidated = async context =>
            {
                var userId = context.Principal?.FindFirstValue(JwtRegisteredClaimNames.Sub)
                    ?? context.Principal?.FindFirstValue(ClaimTypes.NameIdentifier);

                if (string.IsNullOrWhiteSpace(userId))
                {
                    context.Fail("Token has no user identifier.");
                    return;
                }

                await using var scope = context.HttpContext.RequestServices.CreateAsyncScope();
                var db = scope.ServiceProvider.GetRequiredService<ProgramContext>();
                var account = await db.Users
                    .AsNoTracking()
                    .IgnoreQueryFilters()
                    .Where(u => u.Id == userId)
                    .Select(u => new { u.IsApproved, u.RegistrationStatus, u.ChurchId })
                    .FirstOrDefaultAsync(context.HttpContext.RequestAborted);

                if (account is null)
                {
                    context.Fail("Account no longer exists.");
                    return;
                }

                // Tokens live for days and carry ChurchId/Role, so revocation and tenant moves
                // would otherwise not take effect until the token expired.
                if (!account.IsApproved || account.RegistrationStatus != RegistrationStatus.Approved)
                {
                    context.Fail("Account is no longer approved.");
                    return;
                }

                var tokenChurchId = context.Principal?.FindFirstValue("ChurchId");
                if (!int.TryParse(tokenChurchId, out var claimChurchId)
                    || account.ChurchId != claimChurchId)
                {
                    context.Fail("Church assignment has changed; sign in again.");
                }
            }
        };
    }
    );





// DbContext
builder.Services.AddDbContext<ProgramContext>(options =>
{
    var cs = SqlServerResilience.PrepareConnectionString(
        builder.Configuration.GetConnectionString("cs")
            ?? throw new InvalidOperationException(
                "Missing required connection string 'ConnectionStrings:cs'. " +
                "Set it in appsettings.Production.json or as an environment variable in the hosting environment."));

    // Migrations live in the DAL project (Church.DAL), not in the API host.
    options.UseSqlServer(
        cs,
        sql => SqlServerResilience.ConfigureEfSqlOptions(
            sql,
            "Church.DAL"));
});


builder.Services.Configure<IdentityOptions>(options =>
{
    options.User.AllowedUserNameCharacters =
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._@+ " +
        "ءآأؤإئابةتثجحخدذرزسشصضطظعغفقكلمنهوىي";

    // Identity's default minimum is 6 characters; church accounts are phone-number based and
    // therefore easy to target, so require a longer passphrase.
    options.Password.RequiredLength = 8;
    options.Password.RequireDigit = true;
    options.Password.RequireLowercase = true;
    options.Password.RequireUppercase = false;
    options.Password.RequireNonAlphanumeric = false;

    // Lockout is only effective because the login path below records failures explicitly.
    options.Lockout.AllowedForNewUsers = true;
    options.Lockout.MaxFailedAccessAttempts = 8;
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
});



builder.Services
    .AddIdentityCore<ApplicationUser>(options => { })
    .AddRoles<IdentityRole>()
    .AddEntityFrameworkStores<ProgramContext>()
    .AddDefaultTokenProviders();

builder.Services.RemoveAll<IUserValidator<ApplicationUser>>();
builder.Services.AddScoped<IUserValidator<ApplicationUser>, Church.BLL.Identity.ApplicationUserValidator>();

// AutoMapper
builder.Services.AddAutoMapper(m => m.AddProfile(new MappingProfile()));

// Flutter Web (and other browser clients) call this API cross-origin; without CORS
// the browser blocks requests after an OPTIONS preflight gets 401 from JWT auth.
// Origins come from configuration ("Cors:AllowedOrigins") so production can be locked to the
// real Flutter Web domain without a rebuild. A wildcard origin is only acceptable in Development.
var allowedOrigins = builder.Configuration
    .GetSection("Cors:AllowedOrigins")
    .Get<string[]>() ?? Array.Empty<string>();

if (!builder.Environment.IsDevelopment() && allowedOrigins.Length == 0)
{
    throw new InvalidOperationException(
        "Missing required configuration 'Cors:AllowedOrigins'. Outside Development the API must " +
        "list the exact Flutter Web origins (e.g. https://app.mychurch.example) instead of allowing any origin.");
}

builder.Services.AddCors(options =>
{
    options.AddPolicy("FlutterWeb", policy =>
    {
        if (allowedOrigins.Length == 0)
        {
            // Development only: local Flutter Web serves from a random localhost port each run.
            policy.SetIsOriginAllowed(_ => true);
        }
        else
        {
            policy.WithOrigins(allowedOrigins);
        }

        policy
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

// Abuse protection for credential and account-creation endpoints. Without this, the login
// endpoint is an unmetered password-guessing oracle reachable from any origin.
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    options.AddPolicy("auth", context => RateLimitPartition.GetFixedWindowLimiter(
        partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        factory: _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = 10,
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0
        }));

    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 300,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0
            }));
});



var app = builder.Build();

// Apply EF migrations and repair PublicId columns if hosting DB is out of sync.
DatabaseBootstrap.ApplyMigrationsAndRepairSchema(app.Services, app.Logger);

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

// Baseline response hardening. Kept minimal deliberately: a Content-Security-Policy is NOT set
// here because the API also serves the static account-deletion/privacy pages and a wrong policy
// would break them; CSP belongs on the Flutter Web host.
app.Use(async (context, next) =>
{
    var headers = context.Response.Headers;
    headers["X-Content-Type-Options"] = "nosniff";
    headers["X-Frame-Options"] = "DENY";
    headers["Referrer-Policy"] = "no-referrer";
    headers["Cross-Origin-Resource-Policy"] = "cross-origin";
    await next();
});

if (!app.Environment.IsProduction())
{
    app.UseHsts();
}

// Swagger documents every route, parameter and schema in the system. Publishing it alongside a
// public deployment hands an attacker a complete API map, so it is limited to non-production.
var swaggerEnabled = !app.Environment.IsProduction()
    || app.Configuration.GetValue<bool>("Swagger:EnableInProduction");

if (swaggerEnabled)
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
}

// If you are NOT running HTTPS (and you see it only listens on http),
// this redirection can prevent reaching Swagger unless HTTPS is configured.
// You can comment it out if needed.
app.UseHttpsRedirection();

app.UseStaticFiles(new StaticFileOptions
{
    OnPrepareResponse = ctx =>
    {
        // UseStaticFiles short-circuits before UseCors; Flutter Web may fetch
        // images cross-origin (especially when custom headers are involved).
        var path = ctx.Context.Request.Path.Value ?? string.Empty;
        if (path.StartsWith("/uploads", StringComparison.OrdinalIgnoreCase) ||
            path.StartsWith("/images", StringComparison.OrdinalIgnoreCase))
        {
            ctx.Context.Response.Headers["Access-Control-Allow-Origin"] = "*";
            ctx.Context.Response.Headers["Access-Control-Allow-Headers"] = "*";
            ctx.Context.Response.Headers["Access-Control-Allow-Methods"] = "GET, HEAD, OPTIONS";
        }
    }
});

// Must run before authentication so OPTIONS preflight succeeds without a JWT.
app.UseCors("FlutterWeb");

app.UseRateLimiter();

//// If you use [Authorize] anywhere, you should enable authentication:
app.UseAuthentication();
app.UseAuthorization();

app.UseMiddleware<TenantContextPopulationMiddleware>();

app.MapControllers();
app.MapGet(
    "/account-deletion",
    (IWebHostEnvironment environment) => Results.File(
        Path.Combine(environment.WebRootPath, "account-deletion", "index.html"),
        "text/html; charset=utf-8"))
    .AllowAnonymous();
app.MapGet(
    "/privacy-policy",
    (IWebHostEnvironment environment) => Results.File(
        Path.Combine(environment.WebRootPath, "privacy-policy", "index.html"),
        "text/html; charset=utf-8"))
    .AllowAnonymous();
app.MapGet(
    "/",
    () => swaggerEnabled ? Results.Redirect("/swagger") : Results.NoContent())
    .AllowAnonymous();
app.Run();
