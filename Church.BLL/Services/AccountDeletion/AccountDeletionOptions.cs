namespace Church.BLL.Services.AccountDeletion
{
    public sealed class AccountDeletionOptions
    {
        public const string SectionName = "AccountDeletion";

        /// <summary>
        /// Public origin of this API host (no trailing slash), used to build confirmation links.
        /// Example: https://mychurchwebapp-....azurewebsites.net
        /// </summary>
        public string? PublicBaseUrl { get; set; }

        public int TokenLifetimeHours { get; set; } = 24;

        public string SupportEmail { get; set; } = "johnpolis122@gmail.com";
    }
}
