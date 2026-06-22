namespace SunDaySchools.BLL.DTOS
{
    public class ServantProfileDto
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? PhoneNumber { get; set; }
        public string? ImageUrl { get; set; }
        public DateOnly? BirthDate { get; set; }
        public DateOnly? JoiningDate { get; set; }
        public DateOnly? SpiritualBirthDate { get; set; }
        public ServantProfileChurchDto? Church { get; set; }
        public ServantProfileMeetingDto? Meeting { get; set; }

        /// <summary>All meetings in the church (Super Admin profile only).</summary>
        public List<ServantProfileMeetingDto> ChurchMeetings { get; set; } = new();

        public List<ServantProfileClassroomDto> Classrooms { get; set; } = new();
    }

    public class ServantProfileChurchDto
    {
        public int Id { get; set; }
        public string PublicId { get; set; } = string.Empty;
        public string? Name { get; set; }
    }

    public class ServantProfileMeetingDto
    {
        public int Id { get; set; }
        public string PublicId { get; set; } = string.Empty;
        public string? Name { get; set; }
    }

    public class ServantProfileClassroomDto
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string? AgeOfMembers { get; set; }
    }

    public class UpdateServantProfileCommand
    {
        public string? Name { get; set; }
        public string? PhoneNumber { get; set; }
        public DateOnly? BirthDate { get; set; }
        public DateOnly? JoiningDate { get; set; }
        public int? ChurchId { get; set; }
        public int? MeetingId { get; set; }
        public string? ImageFileName { get; set; }
        public string? ImageUrl { get; set; }
        public List<int>? ClassroomIds { get; set; }
    }
}
