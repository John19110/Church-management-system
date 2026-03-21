using System;

namespace SunDaySchools.BLL.Exceptions
{
    public class AccountNotApprovedException : Exception
    {
        public AccountNotApprovedException()
            : base("Your account is waiting for church admin approval.")
        {
        }

        public AccountNotApprovedException(string message)
            : base(message)
        {
        }
    }
}