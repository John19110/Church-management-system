using System;

namespace Church.BLL.DTOS.AccountDtos
{
    /// <summary>
    /// A church user awaiting Super Admin approval. Carries everything the
    /// Pending Users card needs (name, phone, requested role/meeting, photo).
    /// </summary>
    public class PendingUserDTO
    {
        public string Id { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;

        /// <summary>Effective identity role: Servant / Admin / SuperAdmin.</summary>
        public string Role { get; set; } = string.Empty;

        /// <summary>Requested role as chosen at registration: Servant / MeetingAdmin / ChurchAdmin.</summary>
        public string? RequestedRole { get; set; }

        /// <summary>Free-text meeting name the user asked to join.</summary>
        public string? RequestedMeetingName { get; set; }

        /// <summary>Meeting Admin phone provided by a servant at registration (routing hint).</summary>
        public string? MeetingAdminPhoneNumber { get; set; }

        /// <summary>Resolved church id the user requested to join.</summary>
        public int? RequestedChurchId { get; set; }

        /// <summary>Public church identifier the user entered at registration.</summary>
        public string? RequestedChurchPublicId { get; set; }

        /// <summary>Resolved meeting id when the user registered with a public Meeting ID.</summary>
        public int? RequestedMeetingId { get; set; }

        /// <summary>Public meeting identifier when registration used a Meeting ID.</summary>
        public string? RequestedMeetingPublicId { get; set; }

        /// <summary>True when the user registered via a public Meeting ID (not church-only).</summary>
        public bool RegisteredViaMeetingId { get; set; }

        public string? ImageUrl { get; set; }
        public string? ImageFileName { get; set; }

        public DateTime CreatedAt { get; set; }
    }
}
