using Church.DAL.Models.CustomFeatures;

namespace Church.BLL.DTOS.CustomFeatures
{
    public class CustomFeatureReadDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
        public bool IsActive { get; set; }
        public int? MeetingId { get; set; }
        public DateTime CreatedAt { get; set; }
        public List<CustomEntityReadDto> Entities { get; set; } = new();
    }

    public class CustomFeatureCreateDto
    {
        public string? Name { get; set; }
        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
    }

    public class CustomFeatureUpdateDto
    {
        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
        public bool? IsActive { get; set; }
    }

    public class CustomEntityReadDto
    {
        public int Id { get; set; }
        public int FeatureId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
        public string PluralDisplayName { get; set; } = string.Empty;
        public string? PluralDisplayNameAr { get; set; }
        public bool IsActive { get; set; }
        public int SortOrder { get; set; }
        public List<CustomEntityFieldReadDto> Fields { get; set; } = new();
        public List<CustomEntityPermissionDto> Permissions { get; set; } = new();
    }

    public class CustomEntityCreateDto
    {
        public string? Name { get; set; }
        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
        public string? PluralDisplayName { get; set; }
        public string? PluralDisplayNameAr { get; set; }
        public int SortOrder { get; set; }
    }

    public class CustomEntityUpdateDto
    {
        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
        public string PluralDisplayName { get; set; } = string.Empty;
        public string? PluralDisplayNameAr { get; set; }
        public bool? IsActive { get; set; }
        public int? SortOrder { get; set; }
    }

    public class CustomEntityFieldOptionDto
    {
        public int? Id { get; set; }
        public string Value { get; set; } = string.Empty;
        public string DisplayText { get; set; } = string.Empty;
        public string? DisplayTextAr { get; set; }
        public int SortOrder { get; set; }
    }

    public class CustomEntityFieldReadDto
    {
        public int Id { get; set; }
        public int EntityId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
        public CustomEntityFieldType FieldType { get; set; }
        public bool IsRequired { get; set; }
        public bool IsUnique { get; set; }
        public bool IsSearchable { get; set; }
        public bool ShowOnList { get; set; }
        public bool ShowOnForm { get; set; }
        public bool ShowOnDetails { get; set; }
        public int DisplayOrder { get; set; }
        public string? Placeholder { get; set; }
        public string? ValidationRegex { get; set; }
        public int? TargetEntityId { get; set; }
        public CustomEntityCoreReference CoreReference { get; set; }
        public List<CustomEntityFieldOptionDto> Options { get; set; } = new();
    }

    public class CustomEntityFieldCreateDto
    {
        public string? Name { get; set; }
        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
        public CustomEntityFieldType FieldType { get; set; }
        public bool IsRequired { get; set; }
        public bool IsUnique { get; set; }
        public bool IsSearchable { get; set; }
        public bool ShowOnList { get; set; } = true;
        public bool ShowOnForm { get; set; } = true;
        public bool ShowOnDetails { get; set; } = true;
        public int DisplayOrder { get; set; }
        public string? Placeholder { get; set; }
        public string? ValidationRegex { get; set; }
        public int? TargetEntityId { get; set; }
        public List<CustomEntityFieldOptionDto>? Options { get; set; }
    }

    public class CustomEntityFieldUpdateDto
    {
        public string DisplayName { get; set; } = string.Empty;
        public string? DisplayNameAr { get; set; }
        public bool? IsRequired { get; set; }
        public bool? IsUnique { get; set; }
        public bool? IsSearchable { get; set; }
        public bool? ShowOnList { get; set; }
        public bool? ShowOnForm { get; set; }
        public bool? ShowOnDetails { get; set; }
        public int? DisplayOrder { get; set; }
        public string? Placeholder { get; set; }
        public string? ValidationRegex { get; set; }
        public List<CustomEntityFieldOptionDto>? Options { get; set; }
    }

    public class CustomEntityPermissionDto
    {
        public string RoleName { get; set; } = string.Empty;
        public bool CanCreate { get; set; }
        public bool CanRead { get; set; }
        public bool CanUpdate { get; set; }
        public bool CanDelete { get; set; }
    }

    public class CustomEntityRecordReadDto
    {
        public int Id { get; set; }
        public int EntityId { get; set; }
        public Dictionary<string, object?> Values { get; set; } = new();
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }

    public class CustomEntityRecordWriteDto
    {
        public Dictionary<string, object?> Values { get; set; } = new();
    }

    public class CustomEntityRecordPageDto
    {
        public IReadOnlyList<CustomEntityRecordReadDto> Items { get; set; } = Array.Empty<CustomEntityRecordReadDto>();
        public int Total { get; set; }
        public int Page { get; set; }
        public int PageSize { get; set; }
    }
}
