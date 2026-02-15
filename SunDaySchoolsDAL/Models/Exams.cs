using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SunDaySchools.Models;

namespace SunDaySchools.DAL.Models
{
    public class Exams
    {
        public int Id { get; set; }

        public List<Child> Children { get; set; }

        public DateOnly ExamDate { get; set; }

        public List<Child> TopChilds { get; set; }

        public string   Notes { get; set; }




    }
}
