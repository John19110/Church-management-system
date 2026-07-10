using Microsoft.AspNetCore.Identity;
using Church.DAL.Models;
using Church.Domain;

namespace Church.DAL.Models
{
    public class ApplicationUser : IdentityUser
    {
        // navigation only (not all users are servants)
        public Servant? ServantProfile { get; set; }

        // multi-tenant relation
        public int? ChurchId { get; set; }

        public ChurchModel? Church { get; set; }

        public int? MeetingId { get; set; }

        public Meeting? Meeting { get; set; }


        // admin approval system
        // Kept for backward compatibility; mirrors (RegistrationStatus == Approved).
        public bool IsApproved { get; set; } = false;

        /// <summary>Pending / Approved / Rejected workflow state for church user approval.</summary>
        public RegistrationStatus RegistrationStatus { get; set; } = RegistrationStatus.Pending;

        /// <summary>Church the user asked to join (resolved from the public church id at registration).</summary>
        public int? RequestedChurchId { get; set; }

        /// <summary>Free-text meeting/class name the user requested to join (e.g. "Preparatory Boys").</summary>
        public string? RequestedMeetingName { get; set; }

        /// <summary>
        /// When the user registers with a public Meeting ID, the resolved meeting they asked to join.
        /// Church-only registrations leave this null.
        /// </summary>
        public int? RequestedMeetingId { get; set; }

        /// <summary>Role the user requested at registration: Servant / MeetingAdmin / ChurchAdmin.</summary>
        public string? RequestedRole { get; set; }

        /// <summary>For Servant registrations: phone of the Meeting Admin responsible for the requested meeting.</summary>
        public string? MeetingAdminPhoneNumber { get; set; }

        // ---- Pending-registration holding fields ----
        // Pending users have no Servant profile yet (created on approval), so the
        // registration photo / dates are held here until the Super Admin approves.

        /// <summary>Registration photo URL (held until the Servant profile is created on approval).</summary>
        public string? ImageUrl { get; set; }

        /// <summary>Registration photo file name (held until the Servant profile is created on approval).</summary>
        public string? ImageFileName { get; set; }

        /// <summary>Birth date captured at registration (transferred to the Servant on approval).</summary>
        public DateOnly? BirthDate { get; set; }

        /// <summary>Joining date captured at registration (transferred to the Servant on approval).</summary>
        public DateOnly? JoiningDate { get; set; }

        /// <summary>Super Admin user id who approved/rejected this registration.</summary>
        public string? ApprovedByUserId { get; set; }

        /// <summary>When the approval/rejection decision was made.</summary>
        public DateTime? ApprovalDate { get; set; }

        /// <summary>Optional reason captured when a registration is rejected.</summary>
        public string? RejectionReason { get; set; }

        /// <summary>True after WhatsApp OTP phone verification succeeds.</summary>
        public bool IsPhoneVerified { get; set; }

        // auditing
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}