using System;

namespace SunDaySchools.BLL.Exceptions
{
    /// <summary>Thrown at login when a user's registration was rejected by the church Super Admin.</summary>
    public class AccountRejectedException : Exception
    {
        public AccountRejectedException()
            : base("Your registration request was rejected.")
        {
        }

        public AccountRejectedException(string message)
            : base(message)
        {
        }
    }
}
