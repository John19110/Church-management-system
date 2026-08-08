namespace Church.DAL.Abstractions
{
    /// <summary>
    /// Canonical values for the <c>Scope</c> claim that drives tenant query filters.
    /// Scope is derived from the caller's role at token issue time, never supplied by the client.
    /// </summary>
    public static class TenantScopes
    {
        /// <summary>Whole church. Issued to SuperAdmin.</summary>
        public const string Church = "Church";

        /// <summary>A single meeting inside a church. Issued to Admin (meeting admin).</summary>
        public const string Meeting = "Meeting";

        /// <summary>Only the classrooms the servant is assigned to or leads. Issued to Servant.</summary>
        public const string Classroom = "Classroom";
    }
}
