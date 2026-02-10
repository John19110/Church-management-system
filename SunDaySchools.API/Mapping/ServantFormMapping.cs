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
        //Extension Method here 

        public static ServantAddDTO ToDto(this ServantAddFormRequest form)
        {
            return new ServantAddDTO
            {

                Name = form.Name,
                JoiningDate = form.JoiningDate,
                BirthDate = form.BirthDate,
                password=form.password,
                PhoneNumber = form.PhoneNumber,
                ClassroomId = form.ClassroomId
            };
        }
    }
}