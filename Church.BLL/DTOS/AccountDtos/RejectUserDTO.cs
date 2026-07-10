namespace Church.BLL.DTOS.AccountDtos
{
    /// <summary>Super Admin rejection payload with an optional reason.</summary>
    public class RejectUserDTO
    {
        public string? Reason { get; set; }
    }
}
