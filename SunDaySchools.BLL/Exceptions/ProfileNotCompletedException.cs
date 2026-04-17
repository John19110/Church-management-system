using System;

namespace SunDaySchools.BLL.Exceptions
{
    /// <summary>
    /// Thrown when a user has a privileged role but no linked <c>Servants</c> row; login and JWT issuance must fail.
    /// </summary>
    public class ProfileNotCompletedException : Exception
    {
        public ProfileNotCompletedException()
            : base("Profile not completed.")
        {
        }

        public ProfileNotCompletedException(string message)
            : base(message)
        {
        }
    }
}
