namespace Church.DAL.Models.CustomFeatures
{
    public class CustomEntityPermission : ChurchEntity
    {
        public int Id { get; set; }
        public int EntityId { get; set; }
        public CustomEntity? Entity { get; set; }

        public string RoleName { get; set; } = string.Empty;
        public bool CanCreate { get; set; }
        public bool CanRead { get; set; }
        public bool CanUpdate { get; set; }
        public bool CanDelete { get; set; }
    }
}
