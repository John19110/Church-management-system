using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.DTOS
{
    public class ServantUpdateDTO
    {

        public int Id { get; set; }
        public string? ImageFileName { get; set; }
        public string? ImageUrl { get; set; }
        public string? Name { get; set; }
        public DateOnly? JoiningDate { get; set; }
        public DateOnly? BirthDate { get; set; }
        public string? PhoneNumber { get; set; }
        public int? ClassroomId { get; set; }
        public string? password { get; set; }

    }
}
    
