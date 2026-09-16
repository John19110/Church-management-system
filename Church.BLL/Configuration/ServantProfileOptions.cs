namespace Church.BLL.Configuration
{
    /// <summary>
    /// Bind from configuration section <c>Servants</c> (see appsettings.json).
    /// </summary>
    public class ServantProfileOptions
    {

        //If a user has the Servant role but doesn't have a Servant database row yet, should we automatically create one?
        public const string SectionName = "Servants";

        /// <summary>
        /// When true, the first request that needs a Servant row will create a minimal
        /// <see cref="Church.Domain.Servant"/> linked to <c>AspNetUsers.Id</c>
        /// if <c>ChurchId</c> is set on the user. Default false (explicit data only).
        /// </summary>
        public bool AutoCreateMissingProfile { get; set; }
    }
}
