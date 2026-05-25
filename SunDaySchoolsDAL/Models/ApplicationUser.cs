using Microsoft.AspNetCore.Identity;
using SunDaySchools.DAL.Models;
using SunDaySchools.Models;

namespace SunDaySchoolsDAL.Models
{
    public class ApplicationUser : IdentityUser
    {
        // navigation only (not all users are servants)
        public Servant? ServantProfile { get; set; }

        // multi-tenant relation
        public int? ChurchId { get; set; }

        public Church? Church { get; set; }

        public int? MeetingId { get; set; }

        public Meeting? Meeting { get; set; }


        // admin approval system
        public bool IsApproved { get; set; } = false;

        /// <summary>True after WhatsApp OTP phone verification succeeds.</summary>
        public bool IsPhoneVerified { get; set; }

        // auditing
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}