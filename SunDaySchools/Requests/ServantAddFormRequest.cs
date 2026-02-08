using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.API.Requests
{
    public class ServantAddFormRequest
    {


        public string? Name { get; set; }
        public DateOnly? JoiningDate { get; set; }
        public DateOnly? BirthDate { get; set; }
        public string? PhoneNumber { get; set; }
        public int? ClassroomId { get; set; }




        public string? password { get; set; }

        // The uploaded file
        // this field is the reason why we made this entire class 
        public IFormFile? Image { get; set; }
    }


}
