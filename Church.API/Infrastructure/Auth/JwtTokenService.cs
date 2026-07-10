using System.IdentityModel.Tokens.Jwt;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Church.BLL.Abstractions;

namespace Church.API.Infrastructure.Auth
{
    public sealed class JwtTokenService : ITokenService
    {
        private readonly IConfiguration _configuration;

        public JwtTokenService(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public string CreateAccessToken(
            IReadOnlyList<TokenClaimDescriptor> claims,
            TimeSpan? lifetime = null)
        {
            var secretKey = _configuration["SecretKey"]
                ?? throw new InvalidOperationException("Missing configuration value 'SecretKey'.");

            var keyBytes = Encoding.UTF8.GetBytes(secretKey);
            var signingCredentials = new SigningCredentials(
                new SymmetricSecurityKey(keyBytes),
                SecurityAlgorithms.HmacSha256);

            var jwtClaims = claims
                .Select(c => new System.Security.Claims.Claim(c.Type, c.Value))
                .ToList();

            var token = new JwtSecurityToken(
                claims: jwtClaims,
                expires: DateTime.UtcNow.Add(lifetime ?? TimeSpan.FromDays(7)),
                signingCredentials: signingCredentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
