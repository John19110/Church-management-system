using Church.BLL.DTOS.UnifiedForms;

namespace Church.BLL.Application.Servants
{
    /// <summary>
    /// Fields the signed-in user must not change on their own profile.
    /// </summary>
    public static class ServantProfileFieldPolicy
    {
        public static readonly IReadOnlySet<string> ReadOnlyFieldKeys =
            new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "classroomId",
                "churchId",
                "meetingId",
                "imageUrl",
                "imageFileName",
            };

        public static SaveEntityFormDto FilterEditableFields(SaveEntityFormDto dto)
        {
            var fields = dto.Fields?
                .Where(f => !ReadOnlyFieldKeys.Contains(f.FieldKey))
                .ToList() ?? new List<UnifiedFieldValueDto>();

            return new SaveEntityFormDto { Fields = fields };
        }
    }
}
