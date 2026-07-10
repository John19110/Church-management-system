using System;

namespace Church.BLL.Exceptions
{
    public class AccountNotApprovedException : Exception
    {
        public AccountNotApprovedException()
            : base("Your account is waiting for approval from the church administrator.")
        {
        }

        public AccountNotApprovedException(string message)
            : base(message)
        {
        }
    }
}