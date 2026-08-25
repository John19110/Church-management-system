using Church.BLL.Abstractions;
using Church.DAL.Abstractions;

namespace Church.BLL.Services.UnifiedForms
{
    internal static class CustomFieldProvisioningContext
    {
        public static bool TryGetChurchId(
            ITenantContext? tenantContext,
            ICurrentUserContext? currentUser,
            out int churchId)
        {
            churchId = 0;

            if (tenantContext?.ChurchId is int fromTenant && fromTenant > 0)
            {
                churchId = fromTenant;
                return true;
            }

            var claimValue = currentUser?.GetClaim("ChurchId");
            return TryParseChurchId(claimValue, out churchId);
        }

        private static bool TryParseChurchId(string? raw, out int churchId)
        {
            churchId = 0;
            return !string.IsNullOrWhiteSpace(raw)
                && int.TryParse(raw, out churchId)
                && churchId > 0;
        }
    }
}
