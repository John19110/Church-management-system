using Church.DAL.Models;

namespace Church.Domain
{
    public class SpiritualCurriculum : ChurchEntity
    {
        public int id { get; set; }
        public string? Name { get; set; }
        public string? Kind { get; set; }
        public string? Price { get; set; }
        public int? NummberOfLessons { get; set; }
        public string? Description { get; set; }
        public bool? Exist { get; set; }
        public string? Place { get; set; }
        public int? NumberOfAvailableTeacherBooks { get; set; }
        public int? NumberOfAvailableStudentBooks { get; set; }  
        public bool? TokeBefore { get; set; }
        public DateOnly? DateOfLastUse { get; set; }

    }
}
