using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Church.DAL.DBcontext;
using Church.DAL.Models;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace Church.API.Infrastructure.DependencyInjection
{
    public static class AuthenticationServiceCollectionExtensions
    {
        public static IServiceCollection AddAuthenticationServices(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            services.AddAuthentication(option =>
                {
                    option.DefaultAuthenticateScheme = "jwt";
                    option.DefaultChallengeScheme = "jwt";
                    option.DefaultForbidScheme = "jwt";
                })
                .AddJwtBearer("jwt", options =>
                {
                    var secretKey = configuration["SecretKey"];
                    if (string.IsNullOrWhiteSpace(secretKey))
                    {
                        throw new InvalidOperationException(
                            "Missing required configuration value 'SecretKey'. " +
                            "Set it in appsettings.Production.json or as an environment variable in the hosting environment.");
                    }

                    // Short HMAC keys make offline brute-force of the signing secret feasible.
                    var secretKeyBytes = Encoding.UTF8.GetBytes(secretKey);
                    if (secretKeyBytes.Length < 32)
                    {
                        throw new InvalidOperationException(
                            "Configuration value 'SecretKey' must be at least 32 bytes (256 bits) to safely sign HS256 tokens.");
                    }

                    options.MapInboundClaims = true;
                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        IssuerSigningKey = new SymmetricSecurityKey(secretKeyBytes),
                        ValidateIssuerSigningKey = true,
                        ValidAlgorithms = new[] { SecurityAlgorithms.HmacSha256 },
                        ValidateLifetime = true,
                        ClockSkew = TimeSpan.FromSeconds(30),
                        ValidateIssuer = false,
                        ValidateAudience = false,
                        NameClaimType = JwtRegisteredClaimNames.Sub,
                        RoleClaimType = ClaimTypes.Role
                    };

                    // Stateless JWTs must stop authorizing immediately after account deletion,
                    // demotion, or church reassignment. Anonymous login/register must ignore a
                    // leftover Bearer token so sign-in is not blocked with HTTP 403.
                    options.Events = new JwtBearerEvents
                    {
                        OnTokenValidated = context =>
                        {
                            if (IsAnonymousRequest(context.HttpContext))
                            {
                                return Task.CompletedTask;
                            }

                            return ValidateAccountStillAuthorizedAsync(context);
                        },
                        OnAuthenticationFailed = context =>
                        {
                            if (IsAnonymousRequest(context.HttpContext))
                            {
                                context.NoResult();
                            }

                            return Task.CompletedTask;
                        }
                    };
                });

            return services;
        }

        private static bool IsAnonymousRequest(HttpContext http)
        {
            if (http.GetEndpoint()?.Metadata.GetMetadata<IAllowAnonymous>() != null)
            {
                return true;
            }

            var path = http.Request.Path;
            return path.StartsWithSegments("/api/account/login")
                || path.StartsWithSegments("/api/account/register-servant")
                || path.StartsWithSegments("/api/account/register-church-superadmin")
                || path.StartsWithSegments("/api/account/register-meeting-admin-new-church");
        }

        /// <summary>
        /// Re-checks the database on every authenticated request. Nested scope is required
        /// because the JWT bearer handler is not itself a request-scoped consumer of
        /// <see cref="ProgramContext"/>.
        /// </summary>
        private static async Task ValidateAccountStillAuthorizedAsync(TokenValidatedContext context)
        {
            var userId = FindClaimValue(
                context.Principal,
                JwtRegisteredClaimNames.Sub,
                ClaimTypes.NameIdentifier);

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

            if (!account.IsApproved || account.RegistrationStatus != RegistrationStatus.Approved)
            {
                context.Fail("Account is no longer approved.");
                return;
            }

            var tokenChurchId = FindClaimValue(context.Principal, "ChurchId", "churchId");
            if (!int.TryParse(tokenChurchId, out var claimChurchId)
                || account.ChurchId != claimChurchId)
            {
                context.Fail("Church assignment has changed; sign in again.");
            }
        }

        private static string? FindClaimValue(ClaimsPrincipal? principal, params string[] types)
        {
            if (principal == null) return null;

            foreach (var type in types)
            {
                var direct = principal.FindFirstValue(type);
                if (!string.IsNullOrWhiteSpace(direct)) return direct;

                var match = principal.Claims.FirstOrDefault(c =>
                    string.Equals(c.Type, type, StringComparison.OrdinalIgnoreCase));
                if (!string.IsNullOrWhiteSpace(match?.Value)) return match!.Value;
            }

            return null;
        }
    }
}
