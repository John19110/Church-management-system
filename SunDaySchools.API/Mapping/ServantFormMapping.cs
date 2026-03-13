using SunDaySchools.API.Requests;
using SunDaySchools.BLL.DTOS;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SunDaySchools.API.Mapping
{
    public static class ServantFormMapping
    {
        //Extension Methods here 

      

        public static ServantUpdateDTO ToUpdateDto(this ServantFormRequest form)
        {
            return new ServantUpdateDTO
            {
                Name = form.Name,
                JoiningDate = form.JoiningDate,
                BirthDate = form.BirthDate,
                PhoneNumber = form.PhoneNumber,
            //    Classrooms = form.Classrooms,
            };
        }
    }
}