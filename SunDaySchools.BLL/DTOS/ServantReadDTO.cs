using Microsoft.AspNetCore.Http;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.DTOS
{
    public class ServantReadDTO
    {
        public int Id { get; set; }
        public string? ImageFileName { get; set; }   // e.g. "c3c2... .jpg"
        public string? ImageUrl { get; set; }
        public string? Name { get; set; }
        public string? password { get; set; }
        public DateOnly? BirthDate { get; set; }

        public DateOnly? JoiningDate { get; set; }
        public string? PhoneNumber { get; set; }
        public int? ClassroomId { get; set; }
        public Classroom? Classroom { get; set; }
    }
}
