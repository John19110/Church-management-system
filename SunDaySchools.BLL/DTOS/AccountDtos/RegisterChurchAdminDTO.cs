namespace SunDaySchools.BLL.DTOS.AccountDtos
{
    public class RegisterChurchAdminDTO
    {
        public string Name { get; set; }

        public string PhoneNumber { get; set; }

        public string Password { get; set; }

        public string ConfirmPassword { get; set; }

        public string ChurchName { get; set; }
    }
}