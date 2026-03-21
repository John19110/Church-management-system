using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.DAL.Models
{
    public class ExamResult : ChurchEntity
    {
        public int Id { get; set; }                 // or composite key (ExamId + ChildId)
        public int ExamId { get; set; }
        public Exam Exam { get; set; } = null!;

        public int MemberId { get; set; }
        public Member Member { get; set; } = null!;

        public int Score { get; set; }              // grade
        public bool IsAbsent { get; set; }          // useful
        public string? Notes { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
