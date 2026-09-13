using Church.DAL.DBcontext;
using static Church.API.Infrastructure.Database.DatabaseSchemaUtilities;

namespace Church.API.Infrastructure.Database
{
    /// <summary>
    /// Defensive repair for AspNetUsers registration-approval columns used by the approval workflow.
    /// </summary>
    internal static class RegistrationSchemaRepair
    {
        public static void Ensure(ProgramContext db, ILogger logger)
        {
            const string table = "AspNetUsers";

            EnsureColumn(db, logger, table, "RegistrationStatus", "int NOT NULL CONSTRAINT [DF_AspNetUsers_RegistrationStatus] DEFAULT(0)");
            EnsureColumn(db, logger, table, "RequestedChurchId", "int NULL");
            EnsureColumn(db, logger, table, "RequestedMeetingId", "int NULL");
            EnsureColumn(db, logger, table, "RequestedMeetingName", "nvarchar(256) NULL");
            EnsureColumn(db, logger, table, "ApprovedByUserId", "nvarchar(450) NULL");
            EnsureColumn(db, logger, table, "ApprovalDate", "datetime2 NULL");
            EnsureColumn(db, logger, table, "RejectionReason", "nvarchar(1024) NULL");
            EnsureColumn(db, logger, table, "RequestedRole", "nvarchar(64) NULL");
            EnsureColumn(db, logger, table, "MeetingAdminPhoneNumber", "nvarchar(32) NULL");
            EnsureColumn(db, logger, table, "ImageUrl", "nvarchar(512) NULL");
            EnsureColumn(db, logger, table, "ImageFileName", "nvarchar(512) NULL");
            EnsureColumn(db, logger, table, "BirthDate", "date NULL");
            EnsureColumn(db, logger, table, "JoiningDate", "date NULL");

            // Backfill: existing approved accounts become Approved; everything else stays Pending(0).
            if (ColumnExists(db, table, "RegistrationStatus") && ColumnExists(db, table, "IsApproved"))
            {
                TryExecute(
                    db,
                    logger,
                    "UPDATE [AspNetUsers] SET [RegistrationStatus] = 1 WHERE [IsApproved] = 1 AND [RegistrationStatus] = 0");
            }

            logger.LogInformation("Registration approval schema verification/repair completed successfully.");
        }
    }
}
