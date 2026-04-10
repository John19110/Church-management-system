namespace SunDaySchools.BLL.Exceptions
{
    /// <summary>
    /// Consistent problem details for missing Servant ↔ user link
    /// (<c>Servants.ApplicationUserId</c> → <c>AspNetUsers.Id</c>).
    /// </summary>
    public static class ServantProfileMessages
    {
        public static string MissingProfileManual() =>
            "Your account has the Servant role but there is no row in Servants for this user. "
            + "Servants.ApplicationUserId must equal AspNetUsers.Id (one row per servant user). "
            + "Fix: complete servant registration, have an admin add you via the API, or insert the Servants row in the database. "
            + "Optional: set Servants:AutoCreateMissingProfile to true in appsettings to create a minimal Servant on first API use when AspNetUsers.ChurchId is set.";

        public static string MissingAfterAutoCreateAttempt() =>
            "Your account has the Servant role but no Servants row exists and auto-create could not run. "
            + "Ensure AspNetUsers.ChurchId is set for this user, or insert Servants manually with ApplicationUserId = AspNetUsers.Id.";
    }
}
