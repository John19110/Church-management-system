using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Church.DAL.DBcontext;
using Church.DAL.Models;
using Microsoft.AspNetCore.Authentication.JwtBearer;
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

                    options.TokenValidationParameters = new TokenValidationParameters
                    {
                        IssuerSigningKey = new SymmetricSecurityKey(secretKeyBytes),
                        ValidateIssuerSigningKey = true,
                        ValidAlgorithms = new[] { SecurityAlgorithms.HmacSha256 },
                        ValidateLifetime = true,
                        ClockSkew = TimeSpan.FromSeconds(30),
                        ValidateIssuer = false,
                        ValidateAudience = false
                    };

                    // Stateless JWTs must stop authorizing immediately after account deletion,
                    // demotion, or church reassignment.
                    options.Events = new JwtBearerEvents
                    {
                        OnTokenValidated = ValidateAccountStillAuthorizedAsync
                    };
                });

            return services;
        }

        /// <summary>
        /// Re-checks the database on every authenticated request. Nested scope is required
        /// because the JWT bearer handler is not itself a request-scoped consumer of
        /// <see cref="ProgramContext"/>.
        /// </summary>
        private static async Task ValidateAccountStillAuthorizedAsync(TokenValidatedContext context)
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
    }
}
