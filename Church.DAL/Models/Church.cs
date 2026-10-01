using Church.Domain;

namespace Church.DAL.Models
{
    public class Church
    {
        public int Id { get; set; }

        public string PublicId { get; set; } = string.Empty;

        public string Name { get; set; }

        public ICollection<Member> Members { get; set; } = new List<Member>();
        public ICollection<Servant> Servants { get; set; } = new List<Servant>();
        public ICollection<Meeting> Meetings { get; set; } = new List<Meeting>();

        public int? PastorId { get; set; }
        public Servant? Pastor { get; set; }

        /// <summary>Comma-separated language codes this church supports, e.g. <c>en,ar</c>.</summary>
        public string SupportedLanguages { get; set; } = "en,ar";

        /// <summary>Fallback language for user-generated content. Must be one of <see cref="SupportedLanguages"/>.</summary>
        public string DefaultLanguage { get; set; } = "en";

        /// <summary>
        /// True after customization languages have been configured (registration or Customization setup).
        /// Existing translations are never deleted when languages are removed from <see cref="SupportedLanguages"/>.
        /// </summary>
        public bool IsCustomizationLanguagesConfigured { get; set; }
    }
}
