namespace Church.DAL.Models.OptionalModules
{
    /// <summary>
    /// Per-organization enablement of a predefined optional module.
    /// Church-wide when <see cref="ChurchEntity.MeetingId"/> is null; meeting-scoped otherwise.
    /// Disabling preserves module data.
    /// </summary>
    public class OrganizationModuleActivation : ChurchEntity
    {
        public int Id { get; set; }

        /// <summary>Stable developer-defined module key, e.g. <c>stock</c>.</summary>
        public string ModuleId { get; set; } = string.Empty;

        public bool IsEnabled { get; set; }

        public DateTime? EnabledAtUtc { get; set; }
        public DateTime? DisabledAtUtc { get; set; }
        public string? UpdatedBy { get; set; }
        public DateTime UpdatedAtUtc { get; set; }
    }
}
