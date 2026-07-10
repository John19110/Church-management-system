using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Church.Domain;

namespace Church.DAL.Models
{
    public class Exam : ChurchEntity
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
