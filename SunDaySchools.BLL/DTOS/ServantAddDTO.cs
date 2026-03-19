using Microsoft.AspNetCore.Http;
using SunDaySchools.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.BLL.DTOS
{
    public class ServantAddDTO
    {


       //        public string? ImageFileName { get; set; }

       // public string ApplicationUserId { get; set; } = default!;

       // public string? Name { get; set; }
        public IFormFile? Image { get; set; }   // ✅ correct way
        public DateOnly? JoiningDate { get; set; }
        public DateOnly? BirthDate { get; set; }
        public List<int> classroomsIds { get; set; }

       //  public string? PhoneNumber { get; set; }

       // public int ChurchId { get; set; }

    }
}
