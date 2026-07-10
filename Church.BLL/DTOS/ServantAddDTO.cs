using Microsoft.AspNetCore.Http;
using Church.Domain;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Church.BLL.DTOS
{
    public class ServantAddDTO
    {



        public IFormFile? Image { get; set; }   // ✅ correct way
        public DateOnly? JoiningDate { get; set; }
        public DateOnly? BirthDate { get; set; }
        public List<int> classroomsIds { get; set; }

 

    }
}
