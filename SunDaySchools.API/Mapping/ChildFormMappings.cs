using SunDaySchools.API.Requests;
using SunDaySchools.BLL.DTOS;

namespace SunDaySchools.API.Mapping
{
    public static class ChildFormMappings
    {

        //Extension Method here 
        public static ChildAddDTO ToDto(this ChildFormRequest form)
        {
            return new ChildAddDTO
            {
                Name1 = form.Name1,
                Name2 = form.Name2,
                Name3 = form.Name3,
                Gender = form.Gender,
                Address = form.Address,
                DateOfBirth = form.DateOfBirth,
                JoiningDate = form.JoiningDate,
                SpiritualDateOfBirth = form.SpiritualDateOfBirth,
                Notes = form.Notes,
                BrothersNames = form.BrothersNames,
                HaveBrothers = form.HaveBrothers,
                ClassroomId = form.ClassroomId,
                PhoneNumbers=form.PhoneNumbers

    };
        }
    }
}
