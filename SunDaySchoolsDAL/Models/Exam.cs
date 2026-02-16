using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SunDaySchools.Models;

namespace SunDaySchools.DAL.Models
{
    public class Exam
    {
        public int Id { get; set; }
        public int? ClassroomId { get; set; }
        public Classroom? Classroom { get; set; }
        public DateOnly ExamDate { get; set; }
        public int MaxScore { get; set; }
        public string   Notes { get; set; }
        public List<ExamResult> Results { get; set; } = new();


    }
}
