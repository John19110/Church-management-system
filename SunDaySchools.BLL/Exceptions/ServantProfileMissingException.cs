namespace SunDaySchools.BLL.Exceptions
{
    /// <summary>
    /// The authenticated user has the Servant role but has no linked Servant row
    /// (or the link could not be resolved). Maps to HTTP 403 Forbidden.
    /// </summary>
    public class ServantProfileMissingException : Exception
    {
        public ServantProfileMissingException(string message)
            : base(message)
        {
        }
    }
}
